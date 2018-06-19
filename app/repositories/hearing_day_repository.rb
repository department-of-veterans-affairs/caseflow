# Hearing Schedule Repository to help build and edit hearing
# master records in VACOLS for Video, TB and CO hearings.
class HearingDayRepository
  class << self
    def create_vacols_hearing!(hearing_hash)
      hearing_hash = HearingMapper.hearing_fields_to_vacols_codes(hearing_hash)
      VACOLS::CaseHearing.create_hearing!(hearing_hash) if hearing_hash.present?
    end

    def update_vacols_hearing!(hearing, hearing_hash)
      hearing_hash = HearingMapper.hearing_fields_to_vacols_codes(hearing_hash)
      hearing.update_hearing!(hearing_hash) if hearing_hash.present?
    end

    def find_hearing_day(hearing_type, hearing_key)
      if hearing_type.nil?
        VACOLS::CaseHearing.find(hearing_key)
      else
        tbyear, tbtrip, tbleg = hearing_key.split("-")
        VACOLS::TravelBoardSchedule.find_by(tbyear: tbyear, tbtrip: tbtrip, tbleg: tbleg)
      end
    end

    def load_days_for_range(start_date, end_date)
      video_and_co = VACOLS::CaseHearing.load_days_for_range(start_date, end_date)
      travel_board = VACOLS::TravelBoardSchedule.load_days_for_range(start_date, end_date)
      [video_and_co, travel_board]
    end

    def load_days_for_regional_office(regional_office, start_date, end_date)
      video_and_co = VACOLS::CaseHearing.load_days_for_regional_office(regional_office, start_date, end_date)
      travel_board = VACOLS::TravelBoardSchedule.load_days_for_regional_office(regional_office, start_date, end_date)
      [video_and_co, travel_board]
    end
  end
end
