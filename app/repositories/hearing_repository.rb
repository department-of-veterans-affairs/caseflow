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

    # rubocop:disable Metrics/MethodLength
    def slot_new_hearing(attrs, override_full_hearing_day_validation: false)
      hearing_day = HearingDay.find(attrs[:hearing_day_id])

      fail HearingDayFull if !override_full_hearing_day_validation && hearing_day.hearing_day_full?

      if attrs[:appeal].is_a?(LegacyAppeal)
        scheduled_for = HearingTimeService.legacy_formatted_scheduled_for(
          scheduled_for: hearing_day.scheduled_for,
          scheduled_time_string: attrs[:scheduled_time_string]
        )
        vacols_hearing = create_vacols_hearing(
          hearing_day: hearing_day,
          appeal: attrs[:appeal],
          scheduled_for: scheduled_for,
          hearing_location_attrs: attrs[:hearing_location_attrs],
          notes: attrs[:notes]
        )
        AppealRepository.update_location!(attrs[:appeal], LegacyAppeal::LOCATION_CODES[:caseflow])
        vacols_hearing
      else
        Hearing.create!(
          appeal: attrs[:appeal],
          hearing_day_id: hearing_day.id,
          hearing_location_attributes: attrs[:hearing_location_attrs] || {},
          scheduled_time: attrs[:scheduled_time_string],
          override_full_hearing_day_validation: override_full_hearing_day_validation,
          notes: attrs[:notes]
        )
      end
    end
    # rubocop:enable Metrics/MethodLength

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
        Raven.extra_context(application: "hearings")
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

    # Gets the regional office to use when mapping the VACOLS hearing date to
    # the local scheduled time.
    #
    # @note Avoid triggering an indirect additional VACOLS load by avoiding calls to the
    #   `hearing` parameter.
    #
    # @note This mirrors `LegacyHearing#regional_office_key`, but is designed to avoid
    #   calls to any VACOLS accessors because those would trigger an additional
    #   query to VACOLS.
    #
    #   The only call here that has the potential to trigger a VACOLS query is
    #   the call to `LegacyHearing#hearing_day`, which can make a call to VACOLS
    #   if the value is not cached in Caseflow.
    #
    # @param hearing       [LegacyHearing] an uninitialized Caseflow legacy hearing
    # @param vacols_record [VACOLS::CaseHearing] a VACOLS case hearing
    #
    # @return [RegionalOffice]
    #   A hash of setter names on a `LegacyHearing` to values
    def regional_office_for_scheduled_timezone(hearing, vacols_record)
      ro_key = if vacols_record.hearing_type == HearingDay::REQUEST_TYPES[:travel] || hearing.hearing_day.nil?
                 vacols_record.hearing_venue || vacols_record.bfregoff
               else
                 hearing.hearing_day&.regional_office || "C"
               end

      RegionalOffice.find!(ro_key) if ro_key.present?
    end

    # Maps attributes on a VACOLS case hearing to attributes on a Caseflow legacy hearing.
    #
    # @note Avoid triggering an indirect additional VACOLS load by avoiding calls to the
    #   `hearing` parameter.
    #
    # @param hearing       [LegacyHearing] an uninitialized Caseflow legacy hearing
    # @param vacols_record [VACOLS::CaseHearing] a VACOLS case hearing
    #
    # @return [Hash]
    #   A hash of setter names on a `LegacyHearing` to values
    #
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def vacols_attributes(hearing, vacols_record)
      date = HearingMapper.datetime_based_on_type(
        datetime: vacols_record.hearing_date,
        regional_office: regional_office_for_scheduled_timezone(hearing, vacols_record),
        type: vacols_record.hearing_type
      )

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
        hearing_day_vacols_id: vacols_record.vdkey,
        bva_poc: vacols_record.vdbvapoc,
        judge_id: hearing.user_id
      }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def create_vacols_hearing(attrs)
      vacols_record = VACOLS::CaseHearing.create_hearing!(
        folder_nr: attrs[:appeal].vacols_id,
        hearing_date: VacolsHelper.format_datetime_with_utc_timezone(attrs[:scheduled_for]),
        vdkey: attrs[:hearing_day].id,
        hearing_type: attrs[:hearing_day].request_type,
        room: attrs[:hearing_day].room,
        board_member: attrs[:hearing_day].judge ? attrs[:hearing_day].judge.vacols_attorney_id : nil,
        vdbvapoc: attrs[:hearing_day].bva_poc,
        notes1: attrs[:notes]
      )

      # Reload the hearing to pull in associated data.
      # Note: using `load_hearing` here is necessary to load in associated data that is not declared in
      # the table (see `VACOLS::CaseHearing#select_hearings`).
      vacols_record = VACOLS::CaseHearing.load_hearing(vacols_record.id)

      hearing = LegacyHearing.assign_or_create_from_vacols_record(vacols_record)
      hearing.hearing_location_attributes = attrs[:hearing_location_attrs] unless attrs[:hearing_location_attrs].nil?
      hearing.save!
      hearing
    end
  end
end
