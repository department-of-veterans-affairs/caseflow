class QueueRepository
  # :nocov:
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

  def self.reassign_case_to_judge!(vacols_id:, date_assigned:, judge_vacols_user_id:, decass_attrs:)
    MetricsService.record("VACOLS: reassign_case_to_judge! #{vacols_id}",
                          service: :vacols,
                          name: "reassign_case_to_judge") do
      # update DECASS table
      update_decass_record(vacols_id, date_assigned, decass_attrs)

      # update location with the judge's slogid
      VACOLS::Case.find(vacols_id).update_vacols_location!(judge_vacols_user_id)
      true
    end
  end

  def self.update_decass_record(vacols_id, date_assigned, decass_attrs)
    check_decass_presence!(vacols_id, date_assigned)
    decass_attrs = QueueMapper.rename_and_validate_decass_attrs(decass_attrs)
    VACOLS::Decass.where(defolder: vacols_id, deassign: date_assigned).update_all(decass_attrs)
  end

  def self.check_decass_presence!(vacols_id, date_assigned)
    unless VACOLS::Decass.find_by(defolder: vacols_id, deassign: date_assigned)
      msg = "Decass record does not exist for vacols_id: #{vacols_id} and date assigned: #{date_assigned}"
      fail Caseflow::Error::QueueRepositoryError, msg
    end
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
    records.group_by(&:vacols_id).each_with_object([]) { |(_k, v), result| result << v.sort_by(&:assigned_to_attorney_date).last }
  end
end
