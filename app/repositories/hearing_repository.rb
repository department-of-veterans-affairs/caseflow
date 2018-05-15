class HearingRepository
  class << self
    # :nocov:
    def fetch_hearings_for_judge(css_id, is_fetching_issues = false)
      records = MetricsService.record("VACOLS: HearingRepository.fetch_hearings_for_judge: #{css_id}",
                                      service: :vacols,
                                      name: "fetch_hearings_for_judge") do
        VACOLS::CaseHearing.hearings_for_judge(css_id) +
          VACOLS::TravelBoardSchedule.hearings_for_judge(css_id)
      end
      hearings = hearings_for(MasterRecordHelper.remove_master_records_with_children(records))

      # To speed up the daily docket and the hearing worksheet page loads, we pull in issues for appeals here.
      load_issues(hearings) if is_fetching_issues
      hearings
    end

    def load_issues(hearings)
      children_hearings = hearings.select { |h| h.master_record == false }
      issues = VACOLS::CaseIssue.descriptions(children_hearings.map(&:appeal_vacols_id))

      appeal_ids = children_hearings.map(&:appeal_id)
      worksheet_issues_for_appeals_hash = worksheet_issues_for_appeals(appeal_ids)

      hearings.map do |hearing|
        next if hearing.master_record
        issues_hash_array = issues[hearing.appeal_vacols_id] || []
        hearing_worksheet_issues = worksheet_issues_for_appeals_hash[hearing.appeal_id] || []
        next unless hearing_worksheet_issues.empty?
        issues_hash_array.map { |i| WorksheetIssue.create_from_issue(hearing.appeal, Issue.load_from_vacols(i)) }
      end
    end

    def hearings_for_appeal(appeal_vacols_id)
      hearings_for(VACOLS::CaseHearing.for_appeal(appeal_vacols_id))
    end

    def hearings_for_appeals(vacols_ids)
      hearings = VACOLS::CaseHearing.for_appeals(vacols_ids)

      hearings.update(hearings) { |_, case_hearings| hearings_for(case_hearings) }
    end

    def update_vacols_hearing!(vacols_record, hearing_hash)
      hearing_hash = HearingMapper.hearing_fields_to_vacols_codes(hearing_hash)
      vacols_record.update_hearing!(hearing_hash.merge(staff_id: vacols_record.slogid)) if hearing_hash.present?
    end

    def load_vacols_data(hearing)
      vacols_record = MetricsService.record("VACOLS: HearingRepository.load_vacols_data: #{hearing.vacols_id}",
                                            service: :vacols,
                                            name: "load_vacols_data") do
        VACOLS::CaseHearing.load_hearing(hearing.vacols_id)
      end

      if vacols_record
        set_vacols_values(hearing, vacols_record)
        true
      else
        fail Caseflow::Error::VacolsRecordNotFound, "Hearing record with vacols id #{hearing.vacols_id} not found."
      end
    rescue ActiveRecord::RecordNotFound
      false
    end

    def number_of_slots(regional_office_key:, type:, date:)
      record = VACOLS::Staff.find_by(stafkey: regional_office_key)
      slots_based_on_type(staff: record, type: type, date: date) if record
    end

    def fetch_dockets_slots(dockets)
      # fetching all the RO keys of the dockets
      regional_office_keys = dockets.map { |_date, docket| docket.regional_office_key }

      # fetching data of all dockets staff based on the regional office keys
      ro_staff = VACOLS::Staff.where(stafkey: regional_office_keys)
      ro_staff_hash = ro_staff.reduce({}) { |acc, record| acc.merge(record.stafkey => record) }

      # returns a hash of docket date (string) as key and number of slots for the docket
      # as they key
      dockets.map do |date, docket|
        record = ro_staff_hash[docket.regional_office_key]
        [date, (slots_based_on_type(staff: record, type: docket.type, date: docket.date) if record)]
      end.to_h
    end

    def appeals_ready_for_hearing(vbms_id)
      AppealRepository.appeals_ready_for_hearing(vbms_id)
    end
    # :nocov:

    def set_vacols_values(hearing, vacols_record)
      hearing.assign_from_vacols(vacols_attributes(vacols_record))
      hearing
    end

    # STAFF.STC2 is the Travel Board limit for Mon and Fri
    # STAFF.STC3 is the Travel Board limit for Tue, Wed, Thur
    # STAFF.STC4 is the Video limit
    def slots_based_on_type(staff:, type:, date:)
      case type
      when :central_office
        11
      when :video
        staff.stc4
      when :travel
        (date.monday? || date.friday?) ? staff.stc2 : staff.stc3
      end
    end

    def hearings_for(case_hearings)
      vacols_ids = case_hearings.map { |record| record[:hearing_pkseq] }.compact

      fetched_hearings = Hearing.where(vacols_id: vacols_ids)
      fetched_hearings_hash = fetched_hearings.index_by { |hearing| hearing.vacols_id.to_i }

      case_hearings.map do |vacols_record|
        next empty_dockets(vacols_record) if master_record?(vacols_record)
        hearing = Hearing.assign_or_create_from_vacols_record(vacols_record,
                                                              fetched_hearings_hash[vacols_record.hearing_pkseq])
        set_vacols_values(hearing, vacols_record)
      end.flatten
    end

    private

    def worksheet_issues_for_appeals(appeal_ids)
      WorksheetIssue.issues_for_appeals(appeal_ids)
        .each_with_object({}) do |issue, hash|
        hash[issue.appeal_id] ||= []
        hash[issue.appeal_id] << issue
      end
    end

    def master_record?(record)
      record.master_record_type.present?
    end

    def empty_dockets(vacols_record)
      values = MasterRecordHelper.values_based_on_type(vacols_record)
      # Travel Board master records have a date range, so we create a master record for each day
      values[:dates].inject([]) do |result, date|
        result << Hearings::MasterRecord.new(date: VacolsHelper.normalize_vacols_datetime(date),
                                             type: values[:type],
                                             master_record: true,
                                             regional_office_key: values[:ro])
        result
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def vacols_attributes(vacols_record)
      # use venue location on the hearing if it exists
      ro = vacols_record.hearing_venue || vacols_record.bfregoff
      type = VACOLS::CaseHearing::HEARING_TYPES[vacols_record.hearing_type.to_sym]
      date = HearingMapper.datetime_based_on_type(datetime: vacols_record.hearing_date,
                                                  regional_office_key: ro,
                                                  type: type)
      {
        vacols_record: vacols_record,
        appeal_vacols_id: vacols_record.folder_nr,
        venue_key: vacols_record.hearing_venue,
        disposition: VACOLS::CaseHearing::HEARING_DISPOSITIONS[vacols_record.hearing_disp.try(:to_sym)],
        representative_name: vacols_record.repname,
        representative: VACOLS::Case::REPRESENTATIVES[vacols_record.bfso][:full_name],
        aod: VACOLS::CaseHearing::HEARING_AODS[vacols_record.aod.try(:to_sym)],
        hold_open: vacols_record.holddays,
        transcript_requested: VACOLS::CaseHearing::BOOLEAN_MAP[vacols_record.tranreq.try(:to_sym)],
        transcript_sent_date: AppealRepository.normalize_vacols_date(vacols_record.transent),
        add_on: VACOLS::CaseHearing::BOOLEAN_MAP[vacols_record.addon.try(:to_sym)],
        notes: vacols_record.notes1,
        veteran_first_name: vacols_record.snamef,
        veteran_middle_initial: vacols_record.snamemi,
        veteran_last_name: vacols_record.snamel,
        appellant_first_name: vacols_record.sspare1,
        appellant_middle_initial: vacols_record.sspare2,
        appellant_last_name: vacols_record.sspare3,
        regional_office_key: ro,
        type: type,
        date: date,
        master_record: false
      }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
