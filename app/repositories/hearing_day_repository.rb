# Hearing Schedule Repository to help build and edit hearing
# master records in VACOLS for Video, TB and CO hearings.
class HearingDayRepository
  class << self
    def create_vacols_hearing!(hearing_hash)
      hearing_hash = HearingDayMapper.hearing_day_field_validations(hearing_hash)
      HearingDayRepository.to_hash(VACOLS::CaseHearing.create_hearing!(hearing_hash)) if hearing_hash.present?
    end

    # Query Operations
    def find_hearing_day(request_type, hearing_key)
      if request_type.nil? || request_type == HearingDay::REQUEST_TYPES[:central] ||
         request_type == HearingDay::REQUEST_TYPES[:video]
        VACOLS::CaseHearing.find_hearing_day(hearing_key)
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

    def fetch_hearing_day_slots(regional_office)
      HearingDocket::SLOTS_BY_TIMEZONE[HearingMapper.timezone(regional_office)]
    end

    def to_hash(hearing_day)
      hearing_day_hash = hearing_day.as_json.each_with_object({}) do |(k, v), result|
        result[HearingDayMapper::COLUMN_NAME_REVERSE_MAP[k.to_sym]] = v
      end
      hearing_day_hash.delete(nil)
      values_hash = hearing_day_hash.each_with_object({}) do |(k, v), result|
        result[k] = if k.to_s == "regional_office" && !v.nil?
                      v[6, v.length]
                    elsif k.to_s == "hearing_date"
                      VacolsHelper.normalize_vacols_datetime(v)
                    else
                      v
                    end
      end
      values_hash
    end
  end
end
