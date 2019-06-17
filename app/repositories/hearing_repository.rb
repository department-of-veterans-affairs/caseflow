# frozen_string_literal: true

# Hearing Prep repository.
class HearingRepository
  class HearingDayFull < StandardError; end

  class << self
    def fetch_hearings_for_parent(hearing_day_id)
      # Implemented by call the array version of this method
      fetch_hearings_for_parents([hearing_day_id]).values.first || []
    end

    def fetch_hearings_for_parents(hearing_day_ids)
      # Get hash of hearings grouped by their hearing day ids
      hearings_for(VACOLS::CaseHearing.hearings_for_hearing_days(hearing_day_ids))
        .group_by { |hearing| hearing.hearing_day_id.to_s }
    end

    def fetch_hearings_for_parents_assigned_to_judge(hearing_day_ids, judge)
      hearings_for(VACOLS::CaseHearing.hearings_for_hearing_days_assigned_to_judge(hearing_day_ids, judge))
        .group_by { |hearing| hearing.hearing_day_id.to_s }
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

    def create_vacols_hearing(hearing_day, appeal, scheduled_for, hearing_location_attrs)
      VACOLS::CaseHearing.create_hearing!(
        folder_nr: appeal.vacols_id,
        hearing_date: VacolsHelper.format_datetime_with_utc_timezone(scheduled_for),
        vdkey: hearing_day.id,
        hearing_type: hearing_day.request_type,
        room: hearing_day.room,
        board_member: hearing_day.judge ? hearing_day.judge.vacols_attorney_id : nil,
        vdbvapoc: hearing_day.bva_poc
      )

      vacols_record = VACOLS::CaseHearing.for_appeal(appeal.vacols_id).find_by(vdkey: hearing_day.id)
      hearing = LegacyHearing.assign_or_create_from_vacols_record(vacols_record)

      hearing.update(hearing_location_attributes: hearing_location_attrs) unless hearing_location_attrs.nil?

      hearing
    end

    def slot_new_hearing(hearing_day_id, scheduled_time_string:, appeal:, hearing_location_attrs: nil)
      hearing_day = HearingDay.find(hearing_day_id)
      fail HearingDayFull if hearing_day.hearing_day_full?

      hearing = if appeal.is_a?(LegacyAppeal)
                  scheduled_for = HearingTimeService.legacy_formatted_scheduled_for(
                    scheduled_for: hearing_day.scheduled_for,
                    scheduled_time_string: scheduled_time_string
                  )
                  vacols_hearing = create_vacols_hearing(hearing_day, appeal, scheduled_for, hearing_location_attrs)
                  AppealRepository.update_location!(appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
                  vacols_hearing
                else
                  Hearing.create!(
                    appeal: appeal,
                    hearing_day_id: hearing_day.id,
                    hearing_location_attributes: hearing_location_attrs || {},
                    scheduled_time: scheduled_time_string
                  )
                end

      hearing
    end

    def load_vacols_data(hearing)
      vacols_record = MetricsService.record("VACOLS: HearingRepository.load_vacols_data: #{hearing.vacols_id}",
                                            service: :vacols,
                                            name: "load_vacols_hearing_data") do
        VACOLS::CaseHearing.load_hearing(hearing.vacols_id)
      end

      if vacols_record
        LegacyHearing.assign_or_create_from_vacols_record(vacols_record)
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

    def set_vacols_values(hearing, vacols_record)
      hearing.assign_from_vacols(vacols_attributes(hearing, vacols_record))
      hearing
    end

    def hearings_for(case_hearings)
      vacols_ids = case_hearings.map { |record| record[:hearing_pkseq] }.compact

      if vacols_ids.uniq.length != vacols_ids.length
        Raven.capture_message("hearings_for has been sent non-unique vacols ids #{vacols_ids}")
      end

      fetched_hearings = LegacyHearing.where(vacols_id: vacols_ids).includes(:appeal, :user, :hearing_views)
      fetched_hearings_hash = fetched_hearings.index_by { |hearing| hearing.vacols_id.to_i }

      case_hearings.map do |vacols_record|
        hearing = LegacyHearing
          .assign_or_create_from_vacols_record(vacols_record,
                                               legacy_hearing: fetched_hearings_hash[vacols_record.hearing_pkseq])
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

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def vacols_attributes(hearing, vacols_record)
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
        aod: VACOLS::CaseHearing::HEARING_AODS[vacols_record.aod.try(:to_sym)],
        hold_open: vacols_record.holddays,
        transcript_requested: VACOLS::CaseHearing::BOOLEAN_MAP[vacols_record.tranreq.try(:to_sym)],
        transcript_sent_date: AppealRepository.normalize_vacols_date(vacols_record.transent),
        add_on: VACOLS::CaseHearing::BOOLEAN_MAP[vacols_record.addon.try(:to_sym)],
        notes: vacols_record.notes1,
        appeal_type: VACOLS::Case::TYPES[vacols_record.bfac],
        docket_number: vacols_record.tinum || "Missing Docket Number",
        veteran_first_name: vacols_record.snamef,
        veteran_middle_initial: vacols_record.snamemi,
        veteran_last_name: vacols_record.snamel,
        appellant_first_name: vacols_record.sspare2,
        appellant_middle_initial: vacols_record.sspare3,
        appellant_last_name: vacols_record.sspare1,
        room: vacols_record.room,
        request_type: vacols_record.hearing_type,
        scheduled_for: date,
        hearing_day_id: vacols_record.vdkey,
        bva_poc: vacols_record.vdbvapoc,
        judge_id: hearing.user_id
      }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
