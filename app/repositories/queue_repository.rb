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

    # rubocop:disable Metrics/MethodLength
    def appeals_by_vacols_ids(vacols_ids)
      appeals = MetricsService.record("VACOLS: fetch appeals and associated info for tasks",
                                      service: :vacols,
                                      name: "appeals_by_vacols_ids") do

        # Run queries to fetch different types of data so the # of queries doesn't increase with
        # the # of appeals. Combine that data manually.
        case_records = QueueRepository.appeal_info_query(vacols_ids)
        aod_by_appeal = aod_query(vacols_ids)
        hearings_by_appeal = Hearing.repository.hearings_for_appeals(vacols_ids)
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
    # rubocop:enable Metrics/MethodLength

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
      case location
      when :bva_dispatch, :quality_review
        update_vacols_for_bva_dispatch(decass_record, location, decass_attrs)
      when :omo_office
        fail Caseflow::Error::QueueRepositoryError, "The work product is not OMO" unless decass_record.omo_request?
      else
        fail Caseflow::Error::QueueRepositoryError, "Invalid location"
      end
      decass_record.update_vacols_location!(LegacyAppeal::LOCATION_CODES[location])
    end

    def tasks_query(css_id)
      records = VACOLS::CaseAssignment.tasks_for_user(css_id)
      filter_duplicate_tasks(records)
    end

    def tasks_for_appeal_query(appeal_id)
      records = VACOLS::CaseAssignment.tasks_for_appeal(appeal_id)
      filter_duplicate_tasks(records)
    end

    def appeal_info_query(vacols_ids)
      VACOLS::Case.includes(:folder, :correspondent, :representatives)
        .find(vacols_ids)
    end

    def aod_query(vacols_ids)
      VACOLS::Case.aod(vacols_ids)
    end
    # :nocov:

    def assign_case_to_attorney!(judge:, attorney:, vacols_id:)
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

    def filter_duplicate_tasks(records)
      # Keep the latest assignment if there are duplicate records
      records.group_by(&:vacols_id).each_with_object([]) do |(_k, v), result|
        result << v.sort_by(&:created_at).last
      end
    end

    private

    def find_decass_record(vacols_id, created_in_vacols_date)
      decass_record = VACOLS::Decass.find_by(defolder: vacols_id, deadtim: created_in_vacols_date)
      unless decass_record
        msg = "Decass record does not exist for vacols_id: #{vacols_id} and date created: #{created_in_vacols_date}"
        fail Caseflow::Error::QueueRepositoryError, msg
      end
      decass_record
    end

    def update_decass_record(decass_record, decass_attrs)
      decass_attrs = QueueMapper.rename_and_validate_decass_attrs(decass_attrs)
      VACOLS::Decass.where(defolder: decass_record.defolder, deadtim: decass_record.deadtim)
        .update_all(decass_attrs)
    end

    def update_location_to_attorney(vacols_id, attorney)
      vacols_case = VACOLS::Case.find(vacols_id)
      fail VACOLS::Case::InvalidLocationError, "Invalid location \"#{attorney.vacols_uniq_id}\"" unless
        attorney.vacols_uniq_id
      vacols_case.update_vacols_location!(attorney.vacols_uniq_id)
      vacols_case.update(bfattid: attorney.vacols_attorney_id)
    end

    def update_vacols_for_bva_dispatch(decass_record, location, decass_attrs)
      unless decass_record.draft_decision?
        msg = "The work product is not decision"
        fail Caseflow::Error::QueueRepositoryError, msg
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
      VACOLS::Case.select("VACOLS.DECASS_COMPLEX(bfkey) as complexity_rating")
        .find_by(bfkey: vacols_id)
        .try(:complexity_rating)
    end
  end
end
