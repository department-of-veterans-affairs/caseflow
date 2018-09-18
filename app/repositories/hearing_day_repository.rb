# Hearing Schedule Repository to help build and edit hearing
# master records in VACOLS for Video, TB and CO hearings.
class HearingDayRepository
  class << self
    def create_vacols_hearing!(hearing_hash)
      hearing_hash = HearingDayMapper.hearing_day_field_validations(hearing_hash)
      VACOLS::CaseHearing.create_hearing!(hearing_hash) if hearing_hash.present?
    end

    def update_vacols_hearing!(hearing, hearing_hash)
      hearing_hash = HearingDayMapper.hearing_day_field_validations(hearing_hash)
      hearing.update_hearing!(hearing_hash) if hearing_hash.present?
    end

    # Bulk Operations
    def create_schedule(scheduled_hearings)
      scheduled_hearings.each do |hearing|
        create_vacols_hearing!(hearing)
      end
    end

    def update_schedule(updated_hearings)
      updated_hearings.each do |hearing|
        hearing_to_update = VACOLS::CaseHearing.find(hearing[:hearing_pkseq])
        hearing.delete(:hearing_pkseq)
        update_vacols_hearing!(hearing_to_update, hearing)
      end
    end

    # Query Operations
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
