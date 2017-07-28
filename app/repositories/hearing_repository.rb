class HearingRepository
  class << self
    # :nocov:
    def upcoming_hearings_for_judge(vacols_user_id, date_diff: 7.days)
      hearings_for(VACOLS::CaseHearing.upcoming_for_judge(vacols_user_id, date_diff: date_diff))
    end

    def hearings_for_appeal(appeal_vacols_id)
      hearings_for(VACOLS::CaseHearing.for_appeal(appeal_vacols_id))
    end

    def update_vacols_hearing!(vacols_id, hearing_hash)
      hearing_hash = transform_hearing_info(hearing_hash)
      VACOLS::CaseHearing.update_hearing!(vacols_id, hearing_hash) unless hearing_hash.empty?
    end
    # :nocov:

    def transform_hearing_info(hearing_hash)
      {
        notes: hearing_hash[:notes].present? ? hearing_hash[:notes][0, 100] : nil,
        disposition: VACOLS::CaseHearing::HEARING_DISPOSITIONS.key(hearing_hash[:disposition]),
        hold_open: hearing_hash[:hold_open],
        aod: VACOLS::CaseHearing::HEARING_AODS.key(hearing_hash[:aod]),
        transcript_requested: VACOLS::CaseHearing::BOOLEAN_MAP.key(hearing_hash[:transcript_requested])
      }.select { |k, _v| hearing_hash.keys.include? k } # only send updates to key/values that are passed
    end

    private

    # :nocov:
    def hearings_for(case_hearings)
      case_hearings.map { |hearing| Hearing.load_from_vacols(hearing) }
    end
    # :nocov:
  end
end
