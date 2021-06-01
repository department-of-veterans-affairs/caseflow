# frozen_string_literal: true

class QueueRepository
  class << self
    # :nocov:
    def transaction
      VACOLS::Record.transaction do
        yield
      end
    end

    def tasks_for_user(css_id)
      MetricsService.record("VACOLS: fetch user tasks",
                            service: :vacols,
                            name: "tasks_for_user") do
        tasks_query(css_id)
      end
    end

    def tasks_for_appeal(appeal_id)
      MetricsService.record("VACOLS: fetch appeal tasks",
                            service: :vacols,
                            name: "tasks_for_appeal") do
        tasks_for_appeal_query(appeal_id)
      end
    end

    def appeals_by_vacols_ids(vacols_ids)
      appeals = MetricsService.record("VACOLS: fetch appeals and associated info for tasks",
                                      service: :vacols,
                                      name: "appeals_by_vacols_ids") do
        # Run queries to fetch different types of data so the # of queries doesn't increase with
        # the # of appeals. Combine that data manually.
        case_records = QueueRepository.appeal_info_query(vacols_ids)
        aod_by_appeal = aod_query(vacols_ids)
        hearings_by_appeal = HearingRepository.hearings_for_appeals(vacols_ids)
        issues_by_appeal = VACOLS::CaseIssue.descriptions(vacols_ids)
        remand_reasons_by_appeal = RemandReasonRepository.load_remand_reasons_for_appeals(vacols_ids)

        case_records.map do |case_record|
          appeal = AppealRepository.build_appeal(case_record)

          appeal.aod = aod_by_appeal[appeal.vacols_id]
          appeal.issues = (issues_by_appeal[appeal.vacols_id] || []).map do |vacols_issue|
            issue = Issue.load_from_vacols(vacols_issue)
            issue.remand_reasons = remand_reasons_by_appeal[appeal.vacols_id][issue.vacols_sequence_id] || []
            issue
          end
          appeal.hearings = hearings_by_appeal[appeal.vacols_id] || []

          appeal
        end
      end

      appeals.map(&:save)
      appeals
    end

    def reassign_case_to_judge!(vacols_id:, created_in_vacols_date:, judge_vacols_user_id:, decass_attrs:)
      decass_record = find_decass_record(vacols_id, created_in_vacols_date)
      # In attorney checkout, we are automatically selecting the judge who
      # assigned the attorney the case. But we also have a drop down for the
      # attorney to select a different judge if they are checking it out to someone else
      if decass_record.deadusr != judge_vacols_user_id
        BusinessMetrics.record(service: :queue, name: "reassign_case_to_different_judge")
      end

      update_decass_record(decass_record, decass_attrs)

      # update location with the judge's slogid
      decass_record.update_vacols_location!(judge_vacols_user_id)
      true
    end

    def sign_decision_or_create_omo!(vacols_id:, created_in_vacols_date:, location:, decass_attrs:)
      decass_record = find_decass_record(vacols_id, created_in_vacols_date)
      if ![:bva_dispatch, :quality_review, :omo_office].include? location
        fail Caseflow::Error::QueueRepositoryError, "Invalid location"
      end

      if decass_record.dereceive && decass_record.dedeadline
        timeliness = (decass_record.dereceive > decass_record.dedeadline) ? "N" : "Y"
      end

      update_decass_record(decass_record, decass_attrs.merge(timeliness: timeliness))
      # When the DAS final review is done by the VLJ and the case is charged to 4E the VLJ,
      # Attorney and Team get updated in the BRIEFF table
      decass_record.reload.case.update(
        bfmemid: decass_record.dememid,
        bfattid: decass_record.deatty,
        bfboard: decass_record.deteam
      )
      assign_case_for_quality_review(decass_record.case) if location == :quality_review

      decass_record.update_vacols_location!(LegacyAppeal::LOCATION_CODES[location])
    end

    def tasks_query(css_id)
      records = VACOLS::CaseAssignment.tasks_for_user(css_id)
      filter_duplicate_tasks(records, css_id)
    end

    def tasks_for_appeal_query(appeal_id)
      records = VACOLS::CaseAssignment.tasks_for_appeal(appeal_id)
      filter_duplicate_tasks(records)
    end

    def appeal_info_query(vacols_ids)
      VACOLS::Case.includes(:folder, :correspondent, :case_issues)
        .find(vacols_ids)
    end

    def aod_query(vacols_ids)
      VACOLS::Case.aod(vacols_ids)
    end
    # :nocov:

    def assign_case_to_attorney!(assigned_by:, judge:, attorney:, vacols_id:)
      transaction do
        unless VACOLS::Case.find(vacols_id).bfcurloc == judge.vacols_uniq_id
          fail Caseflow::Error::LegacyCaseAlreadyAssignedError, message: "Case already assigned"
        end

        update_location_to_attorney(vacols_id, attorney)

        attrs = assign_to_attorney_attrs(vacols_id, attorney, assigned_by)

        incomplete_record = incomplete_decass_record(vacols_id)
        if incomplete_record.present?
          return update_decass_record(incomplete_record, attrs.merge(work_product: nil))
        end

        create_decass_record(attrs.merge(adding_user: assigned_by.vacols_uniq_id))
      end
    end

    def assign_to_attorney_attrs(vacols_id, attorney, assigned_by)
      {
        case_id: vacols_id,
        attorney_id: attorney.vacols_attorney_id,
        group_name: attorney.vacols_group_id[0..2],
        assigned_to_attorney_date: VacolsHelper.local_date_with_utc_timezone,
        deadline_date: VacolsHelper.local_date_with_utc_timezone + 30.days,
        complexity_rating: decass_complexity_rating(vacols_id),
        modifying_user: assigned_by.vacols_uniq_id
      }
    end

    def incomplete_decass_record(vacols_id)
      VACOLS::Decass
        .where(defolder: vacols_id)
        .where.not(deprod: %w[REA REU DEV VHA IME AFI OTV OTI]).or(
          VACOLS::Decass.where(defolder: vacols_id).where("DEOQ IS NULL")
        ).first
    end

    def reassign_case_to_attorney!(judge:, attorney:, vacols_id:, created_in_vacols_date:)
      transaction do
        update_location_to_attorney(vacols_id, attorney)

        decass_record = find_decass_record(vacols_id, created_in_vacols_date)
        update_decass_record(decass_record,
                             attorney_id: attorney.vacols_attorney_id,
                             group_name: attorney.vacols_group_id[0..2],
                             assigned_to_attorney_date: VacolsHelper.local_date_with_utc_timezone,
                             deadline_date: VacolsHelper.local_date_with_utc_timezone + 30.days,
                             modifying_user: judge.vacols_uniq_id)
      end
    end

    def any_task_assigned_by_user?(appeal, user)
      VACOLS::Decass.where(defolder: appeal.vacols_id, demdusr: user.vacols_uniq_id).exists?
    end

    def filter_duplicate_tasks(records, css_id = nil)
      # Keep the latest updated assignment if there are duplicate records
      records.group_by(&:vacols_id).each_with_object([]) do |(_k, v), result|
        next result << v.first if v.size == 1

        user = User.find_by_css_id(css_id) if css_id
        # If user is an attorney, find all associated with the user's attorney_id
        if user&.station_id == User::BOARD_STATION_ID && attorney_id_match_found?(v, user)
          v.select! { |task| task.attorney_id == user.vacols_attorney_id }
        end
        # If DAS record doesn't have updated_at date, put it at the beginning of the list
        result << (v.reject(&:updated_at) + v.select(&:updated_at).sort_by(&:updated_at)).last
      end
    end

    def update_location_to_judge(vacols_id, judge)
      vacols_case = VACOLS::Case.find(vacols_id)
      fail VACOLS::Case::InvalidLocationError, "Invalid location \"#{judge.vacols_uniq_id}\"" unless
        judge.vacols_uniq_id

      vacols_case.update_vacols_location!(judge.vacols_uniq_id)
    end

    private

    def attorney_id_match_found?(records, user)
      user.attorney_in_vacols? && records.map(&:attorney_id).include?(user.vacols_attorney_id)
    end

    def find_decass_record(vacols_id, created_in_vacols_date)
      decass_record = VACOLS::Decass.find_by(defolder: vacols_id, deadtim: created_in_vacols_date)
      unless decass_record
        msg = "Decass record does not exist for vacols_id: #{vacols_id} and date created: #{created_in_vacols_date}"
        fail Caseflow::Error::QueueRepositoryError, msg
      end
      decass_record
    end

    def update_decass_record(decass_record, decass_attrs)
      decass_attrs = QueueMapper.new(decass_attrs).rename_and_validate_decass_attrs
      VACOLS::Decass.where(defolder: decass_record.defolder, deadtim: decass_record.deadtim)
        .update_all(decass_attrs)
      decass_record.reload
    end

    def create_decass_record(decass_attrs)
      decass_attrs = decass_attrs.merge(added_at_date: VacolsHelper.local_date_with_utc_timezone)
      decass_attrs = QueueMapper.new(decass_attrs).rename_and_validate_decass_attrs
      VACOLS::Decass.create!(decass_attrs)
    end

    def update_location_to_attorney(vacols_id, attorney)
      vacols_case = VACOLS::Case.find(vacols_id)
      fail VACOLS::Case::InvalidLocationError, "Invalid location \"#{attorney.vacols_uniq_id}\"" unless
        attorney.vacols_uniq_id

      vacols_case.update_vacols_location!(attorney.vacols_uniq_id)
      vacols_case.update(bfattid: attorney.vacols_attorney_id)
    end

    def assign_case_for_quality_review(vacols_case)
      VACOLS::DecisionQualityReview.create(
        qryymm: Time.zone.now.strftime("%y") + Time.zone.now.strftime("%m"),
        qrsmem: vacols_case.bfmemid,
        qrfolder: vacols_case.bfkey,
        qrseldate: VacolsHelper.local_date_with_utc_timezone,
        qrteam: vacols_case.bfboard[0..1]
      )
    end

    def decass_complexity_rating(vacols_id)
      query = "#{Rails.application.config.vacols_db_name}.DECASS_COMPLEX(bfkey) as complexity_rating"
      VACOLS::Case.select(query)
        .find_by(bfkey: vacols_id)
        .try(:complexity_rating)
    end
  end
end
