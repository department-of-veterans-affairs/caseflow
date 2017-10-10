class HearingRepository
  class << self
    # :nocov:
    def upcoming_hearings_for_judge(css_id)
      hearings_for(VACOLS::CaseHearing.upcoming_for_judge(css_id))
    end

    def hearings_for_appeal(appeal_vacols_id)
      hearings_for(VACOLS::CaseHearing.for_appeal(appeal_vacols_id))
    end

    def update_vacols_hearing!(vacols_record, hearing_hash)
      hearing_hash = HearingMapper.hearing_fields_to_vacols_codes(hearing_hash)
      vacols_record.update_hearing!(hearing_hash) if hearing_hash.present?
    end

    def load_vacols_data(hearing)
      vacols_record = VACOLS::CaseHearing.load_hearing(hearing.vacols_id)
      set_vacols_values(hearing, vacols_record)
      true
    rescue ActiveRecord::RecordNotFound
      false
    end

    def number_of_slots(regional_office_key:, type:, date:)
      record = VACOLS::Staff.find_by(stafkey: regional_office_key)
      slots_based_on_type(staff: record, type: type, date: date) if record
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

    # Fields such as 'type', 'regional_office_key' are stored in different places
    # depending whether it is a child record or a master record (video or travel_board)
    def values_based_on_type(vacols_record)
      case vacols_record.master_record_type
      when :video
        ro = vacols_record.folder_nr.split(" ").second
        type = :video
      else
        ro = vacols_record.bfregoff
        type = VACOLS::CaseHearing::HEARING_TYPES[vacols_record.hearing_type.to_sym]
      end
      date = hearing_datetime(vacols_record.hearing_date, ro) if vacols_record.hearing_date && ro

      { type: type,
        regional_office_key: ro,
        date: date
      }
    end

    # The hearing datetime reflect the timezone of the local RO,
    # So we append the timezone based on the regional office location
    # And then convert the date to Eastern Time
    def hearing_datetime(datetime, regional_office_key)
      timezone = VACOLS::RegionalOffice::CITIES[regional_office_key][:timezone]
      # asctime - returns a canonical string representation of time
      datetime.asctime.in_time_zone(timezone).in_time_zone("Eastern Time (US & Canada)")
    end

    private

    # :nocov:
    def hearings_for(case_hearings)
      case_hearings.map do |vacols_record|
        hearing = Hearing.create_from_vacols_record(vacols_record)
        set_vacols_values(hearing, vacols_record)
      end
    end
    # :nocov:

    def vacols_attributes(vacols_record)
      attrs = values_based_on_type(vacols_record)
      attrs.merge(
        vacols_record: vacols_record,
        venue_key: vacols_record.hearing_venue,
        disposition: VACOLS::CaseHearing::HEARING_DISPOSITIONS[vacols_record.hearing_disp.try(:to_sym)],
        representative_name: vacols_record.repname,
        representative: VACOLS::Case::REPRESENTATIVES[vacols_record.bfso][:full_name],
        aod: VACOLS::CaseHearing::HEARING_AODS[vacols_record.aod.try(:to_sym)],
        hold_open: vacols_record.holddays,
        transcript_requested: VACOLS::CaseHearing::BOOLEAN_MAP[vacols_record.tranreq.try(:to_sym)],
        add_on: VACOLS::CaseHearing::BOOLEAN_MAP[vacols_record.addon.try(:to_sym)],
        notes: vacols_record.notes1,
        master_record: vacols_record.master_record?
      )
    end
  end
end
