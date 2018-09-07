# Hearing Schedule Repository to help build and edit hearing
# master records in VACOLS for Video, TB and CO hearings.
class HearingDayRepository
  class << self
    def create_vacols_hearing!(hearing_hash)
      hearing_hash = HearingDayMapper.hearing_day_field_validations(hearing_hash)
      self.to_canonical_hash(VACOLS::CaseHearing.create_hearing!(hearing_hash)) if hearing_hash.present?
    end

    def update_vacols_hearing!(hearing, hearing_hash)
      hearing_hash = HearingDayMapper.hearing_day_field_validations(hearing_hash)
      hearing.update_hearing!(hearing_hash) if hearing_hash.present?
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
      video_and_co = VACOLS::CaseHearing.load_days_for_range(start_date, end_date).each_with_object([]) do |hearing, result|
        result << self.to_canonical_hash(hearing)
      end
      travel_board = VACOLS::TravelBoardSchedule.load_days_for_range(start_date, end_date)
      [video_and_co, travel_board]
    end

    def load_days_for_regional_office(regional_office, start_date, end_date)
      video_and_co = VACOLS::CaseHearing.load_days_for_regional_office(regional_office, start_date, end_date).each_with_object([]) do |hearing, result|
        result << self.to_canonical_hash(hearing)
      end
      travel_board = VACOLS::TravelBoardSchedule.load_days_for_regional_office(regional_office, start_date, end_date)
      [video_and_co, travel_board]
    end

    def to_canonical_hash(hearing)
      hearing_hash = hearing.as_json.each_with_object({}) do |(k, v), result|
        result[HearingDayMapper::COLUMN_NAME_REVERSE_MAP[k.to_sym]] = v
      end
      hearing_hash.delete(nil)
      values_hash = hearing_hash.each_with_object({}) do |(k, v), result|
        if k.to_s == "room_info"
          result[k] = HearingDayMapper.label_for_room(v)
        elsif k.to_s == "regional_office" && !v.nil?
          ro = v[6, v.length]
          result[k] = HearingDayMapper.city_for_regional_office(ro)
        elsif k.to_s == "hearing_type"
          result[k] = HearingDayMapper.label_for_type(v)
        elsif k.to_s == "hearing_date"
          result[k] = VacolsHelper.normalize_vacols_datetime(v)
        else
          result[k] = v
        end
      end
      values_hash
    end
  end
end
