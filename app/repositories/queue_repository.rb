class QueueRepository
  # :nocov:
  def self.transaction
    VACOLS::Record.transaction do
      yield
    end
  end

  def self.tasks_for_user(css_id)
    MetricsService.record("VACOLS: fetch user tasks",
                          service: :vacols,
                          name: "tasks_for_user") do
      tasks_query(css_id)
    end
  end

  def self.appeals_from_tasks(tasks)
    vacols_ids = tasks.map(&:vacols_id)

    appeals = MetricsService.record("VACOLS: fetch appeals and associated info for tasks",
                                    service: :vacols,
                                    name: "appeals_from_tasks") do
      case_records = QueueRepository.appeal_info_query(vacols_ids)
      aod_by_appeal = aod_query(vacols_ids)
      hearings_by_appeal = Hearing.repository.hearings_for_appeals(vacols_ids)
      issues_by_appeal = VACOLS::CaseIssue.descriptions(vacols_ids)

      case_records.map do |case_record|
        appeal = AppealRepository.build_appeal(case_record)

        appeal.aod = aod_by_appeal[appeal.vacols_id]
        appeal.issues = (issues_by_appeal[appeal.vacols_id] || []).map { |issue| Issue.load_from_vacols(issue) }
        appeal.hearings = hearings_by_appeal[appeal.vacols_id] || []

        appeal
      end
    end

    appeals.map(&:save)
    appeals
  end

  def self.assign_case_to_attorney!(judge:, attorney:, vacols_id:)
    transaction do
      update_location_to_attorney(vacols_id, attorney)

      VACOLS::Decass.create!(
        defolder: vacols_id,
        deatty: attorney.vacols_attorney_id,
        deteam: attorney.vacols_group_id[0..2],
        deadusr: judge.vacols_uniq_id,
        deadtim: VacolsHelper.local_date_with_utc_timezone,
        dedeadline: VacolsHelper.local_date_with_utc_timezone + 30.days,
        deassign: VacolsHelper.local_date_with_utc_timezone,
        deicr: decass_complexity_rating(vacols_id)
      )
    end
  end

  def self.reassign_case_to_attorney!(judge:, attorney:, vacols_id:, created_in_vacols_date:)
    transaction do
      update_location_to_attorney(vacols_id, attorney)

      decass_record = find_decass_record(vacols_id, created_in_vacols_date)
      update_decass_record(decass_record,
                           attorney_id: attorney.vacols_attorney_id,
                           group_name: attorney.vacols_group_id[0..2],
                           assigned_to_attorney_date: VacolsHelper.local_date_with_utc_timezone,
                           modifying_user: judge.vacols_uniq_id)
    end
  end

  def self.update_location_to_attorney(vacols_id, attorney)
    vacols_case = VACOLS::Case.find(vacols_id)
    vacols_case.update_vacols_location!(attorney.vacols_uniq_id)
    vacols_case.update(bfattid: attorney.vacols_attorney_id)
  end

  def self.decass_complexity_rating(vacols_id)
    VACOLS::Case.select("VACOLS.DECASS_COMPLEX(bfkey) as complexity_rating")
      .find_by(bfkey: vacols_id)
      .try(:complexity_rating)
  end

  def self.reassign_case_to_judge!(vacols_id:, created_in_vacols_date:, judge_vacols_user_id:, decass_attrs:)
    decass_record = find_decass_record(vacols_id, created_in_vacols_date)
    # In attorney checkout, we are automatically selecting the judge who
    # assigned the attorney the case. But we also have a drop down for the
    # attorney to select a different judge if they are checking it out to someone else
    if decass_record.deadusr != judge_vacols_user_id
      BusinessMetrics.record(service: :queue, name: "reassign_case_to_different_judge")
    end

    update_decass_record(decass_record, decass_attrs)

    # update location with the judge's slogid
    VACOLS::Case.find(vacols_id).update_vacols_location!(judge_vacols_user_id)
    true
  end

  def self.sign_decision_or_create_omo!(vacols_id:, created_in_vacols_date:, type:, decass_attrs:)
    vacols_case = VACOLS::Case.find(vacols_id)
    decass_record = find_decass_record(vacols_id, created_in_vacols_date)
    if type == :draft_decision
      vacols_case.update_vacols_location!(LOCATION_CODES[:bva_dispatch])
      update_decass_record(decass_record, decass_attrs)
    else
      # Validate by checking that the work product is OMO (overtime or not)
      vacols_case.update_vacols_location!(LOCATION_CODES[:omo_office])
    end
  end

  def self.find_decass_record(vacols_id, created_in_vacols_date)
    decass_record = VACOLS::Decass.find_by(defolder: vacols_id, deadtim: created_in_vacols_date)
    unless decass_record
      msg = "Decass record does not exist for vacols_id: #{vacols_id} and date created: #{created_in_vacols_date}"
      fail Caseflow::Error::QueueRepositoryError, msg
    end
    decass_record
  end

  def self.update_decass_record(decass_record, decass_attrs)
    decass_attrs = QueueMapper.rename_and_validate_decass_attrs(decass_attrs)
    VACOLS::Decass.where(defolder: decass_record.defolder, deadtim: decass_record.deadtim)
      .update_all(decass_attrs)
  end

  def self.tasks_query(css_id)
    records = VACOLS::CaseAssignment.tasks_for_user(css_id)
    filter_duplicate_tasks(records)
  end

  def self.appeal_info_query(vacols_ids)
    VACOLS::Case.includes(:folder, :correspondent, :representative)
      .find(vacols_ids)
  end

  def self.aod_query(vacols_ids)
    VACOLS::Case.aod(vacols_ids)
  end
  # :nocov:

  def self.filter_duplicate_tasks(records)
    # Keep the latest assignment if there are duplicate records
    records.group_by(&:vacols_id).each_with_object([]) do |(_k, v), result|
      result << v.sort_by(&:created_at).last
    end
  end
end
