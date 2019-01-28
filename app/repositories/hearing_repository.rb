# Hearing Prep repository.
class HearingRepository
  class NoOpenSlots < StandardError; end
  class LockedHearingDay < StandardError; end

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

    def fetch_video_hearings_for_parent(parent_hearing_pkseq)
      # Implemented by call the array version of this method
      fetch_video_hearings_for_parents([parent_hearing_pkseq]).values.first || []
    end

    def fetch_video_hearings_for_parents(parent_hearings_pkseq)
      # Get hash of hearings grouped by their hearing day ids
      VACOLS::CaseHearing.video_hearings_for_master_records(parent_hearings_pkseq)
        .group_by { |record| record.vdkey.to_s }.transform_values do |value|
        hearings_for(value)
      end
    end

    def fetch_co_hearings_for_date(parent_hearing_date)
      # Implemented by call the array version of this method
      fetch_co_hearings_for_dates([parent_hearing_date]).values.first || []
    end

    def fetch_co_hearings_for_dates(parent_hearing_dates)
      # Get hash of hearings grouped by their hearing day date string. Note we do
      # hearing_date.utc.to_date.to_s to avoid timezone issues and make it consistent
      # with how the date is stored in the HearingDay table.
      VACOLS::CaseHearing.co_hearings_for_master_records(parent_hearing_dates)
        .group_by { |record| record.hearing_date.utc.to_date.to_s }.transform_values do |value|
        hearings_for(value)
      end
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

    def to_hash(hearing)
      hearing.as_json.each_with_object({}) do |(k, v), result|
        result[k.to_sym] = v
      end
    end

    def slot_new_hearing(parent_record_id, time, appeal)
      hearing_day = HearingDay.find_hearing_day(nil, parent_record_id)
      hearing_datetime = hearing_day[:scheduled_for].to_datetime.change(
        hour: time["h"].to_i,
        minute: time["m"].to_i,
        offset: time["offset"]
      )

      if hearing_day[:request_type] == "C"
        create_child_co_hearing(hearing_datetime, appeal)
      else
        create_child_video_hearing(parent_record_id, hearing_datetime, appeal)
      end
    end

    def create_child_co_hearing(hearing_date_str, appeal)
      hearing_day = HearingDay.find_by(request_type: "C", scheduled_for: hearing_date_str.to_date)
      fail LockedHearingDay, message: "Locked hearing day" if hearing_day.lock

      attorney_id = hearing_day.judge ? hearing_day.judge.vacols_attorney_id : nil

      VACOLS::CaseHearing.create_child_hearing!(
        folder_nr: appeal.vacols_id,
        hearing_date: VacolsHelper.format_datetime_with_utc_timezone(hearing_date_str),
        vdkey: hearing_day.id,
        hearing_type: hearing_day.request_type,
        room: hearing_day.room,
        board_member: attorney_id,
        vdbvapoc: hearing_day.bva_poc
      )
    end

    def create_child_video_hearing(hearing_pkseq, hearing_date, appeal)
      if hearing_date.to_date > HearingDay::CASEFLOW_V_PARENT_DATE || appeal.is_a?(Appeal)
        return create_caseflow_child_video_hearing(hearing_pkseq, hearing_date, appeal)
      end

      hearing = VACOLS::CaseHearing.find(hearing_pkseq)

      VACOLS::CaseHearing.create_child_hearing!(
        folder_nr: appeal.vacols_id,
        hearing_date: VacolsHelper.format_datetime_with_utc_timezone(hearing_date),
        vdkey: hearing.hearing_pkseq,
        hearing_type: "V",
        room: hearing.room,
        board_member: hearing.board_member,
        vdbvapoc: hearing.vdbvapoc
      )
    end

    def create_caseflow_child_video_hearing(id, hearing_date, appeal)
      hearing_day = HearingDay.find(id)
      fail LockedHearingDay, message: "Locked hearing day" if hearing_day.lock

      if appeal.is_a?(LegacyAppeal)
        VACOLS::CaseHearing.create_child_hearing!(
          folder_nr: appeal.vacols_id,
          hearing_date: VacolsHelper.format_datetime_with_utc_timezone(hearing_date),
          vdkey: hearing_day.id,
          hearing_type: hearing_day.request_type,
          room: hearing_day.room,
          board_member: hearing_day.judge ? hearing_day.judge.vacols_attorney_id : nil,
          vdbvapoc: hearing_day.bva_poc
        )
      else
        Hearing.create!(
          appeal: appeal,
          hearing_day_id: hearing_day.id,
          scheduled_time: hearing_date
        )
      end
    end

    def load_vacols_data(hearing)
      vacols_record = MetricsService.record("VACOLS: HearingRepository.load_vacols_data: #{hearing.vacols_id}",
                                            service: :vacols,
                                            name: "load_vacols_hearing_data") do
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

    def appeals_ready_for_hearing(vbms_id)
      AppealRepository.appeals_ready_for_hearing(vbms_id)
    end
    # :nocov:

    def set_vacols_values(hearing, vacols_record)
      hearing.assign_from_vacols(vacols_attributes(vacols_record))
      hearing
    end

    def hearings_for(case_hearings)
      vacols_ids = case_hearings.map { |record| record[:hearing_pkseq] }.compact

      fetched_hearings = LegacyHearing.where(vacols_id: vacols_ids).includes(:appeal, :user)
      fetched_hearings_hash = fetched_hearings.index_by { |hearing| hearing.vacols_id.to_i }

      case_hearings.map do |vacols_record|
        next empty_dockets(vacols_record) if master_record?(vacols_record)

        hearing = LegacyHearing.assign_or_create_from_vacols_record(vacols_record,
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
        result << Hearings::MasterRecord.new(scheduled_for: VacolsHelper.normalize_vacols_datetime(date),
                                             request_type: values[:request_type],
                                             master_record: true,
                                             regional_office_key: values[:ro])
        result
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def vacols_attributes(vacols_record)
      # use venue location on the hearing if it exists
      ro = vacols_record.hearing_venue || vacols_record.bfregoff
      date = HearingMapper.datetime_based_on_type(datetime: vacols_record.hearing_date,
                                                  regional_office_key: ro,
                                                  type: vacols_record.hearing_type)
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
        appellant_address_line_1: vacols_record.saddrst1,
        appellant_address_line_2: vacols_record.saddrst2,
        appellant_city: vacols_record.saddrcty,
        appellant_state: vacols_record.saddrstt,
        appellant_country: vacols_record.saddrcnty,
        appellant_zip: vacols_record.saddrzip,
        appeal_type: VACOLS::Case::TYPES[vacols_record.bfac],
        docket_number: vacols_record.tinum || "Missing Docket Number",
        veteran_first_name: vacols_record.snamef,
        veteran_middle_initial: vacols_record.snamemi,
        veteran_last_name: vacols_record.snamel,
        appellant_first_name: vacols_record.sspare2,
        appellant_middle_initial: vacols_record.sspare3,
        appellant_last_name: vacols_record.sspare1,
        room: vacols_record.room,
        regional_office_key: ro,
        request_type: vacols_record.hearing_type,
        scheduled_for: date,
        hearing_day_id: vacols_record.vdkey,
        master_record: false
      }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
