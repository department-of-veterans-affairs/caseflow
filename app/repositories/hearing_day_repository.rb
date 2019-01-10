# Hearing Schedule Repository to help build and edit hearing
# master records in VACOLS for Video, TB and CO hearings.
class HearingDayRepository
  class << self
    def create_vacols_hearing!(hearing_hash)
      hearing_hash = HearingDayMapper.hearing_day_field_validations(hearing_hash)
      to_canonical_hash(VACOLS::CaseHearing.create_hearing!(hearing_hash)) if hearing_hash.present?
    end

    # Query Operations
    def find_hearing_day(hearing_type, hearing_key)
      if hearing_type.nil? || hearing_type == "V" || hearing_type == "C"
        VACOLS::CaseHearing.find_hearing_day(hearing_key)
      else
        tbyear, tbtrip, tbleg = hearing_key.split("-")
        VACOLS::TravelBoardSchedule.find_by(tbyear: tbyear, tbtrip: tbtrip, tbleg: tbleg)
      end
    end

    def load_days_for_range(start_date, end_date)
      video_and_co = VACOLS::CaseHearing.load_days_for_range(start_date, end_date)
        .each_with_object([]) do |hearing, result|
        result << to_canonical_hash(hearing)
      end
      removed_children_records = video_and_co.reject do |hearing_day|
        hearing_day[:hearing_type] == "C" && hearing_day[:scheduled_for] > HearingDay::CASEFLOW_CO_PARENT_DATE
      end
      travel_board = VACOLS::TravelBoardSchedule.load_days_for_range(start_date, end_date)
      [removed_children_records.uniq do |hearing_day|
        [hearing_day[:scheduled_for].to_date,
         hearing_day[:room],
         hearing_day[:hearing_type]]
      end, travel_board]
    end

    def load_days_for_central_office(start_date, end_date)
      end_date = (end_date > HearingDay::CASEFLOW_CO_PARENT_DATE) ? HearingDay::CASEFLOW_CO_PARENT_DATE : end_date
      video_and_co = VACOLS::CaseHearing.load_days_for_central_office(start_date, end_date)
        .each_with_object([]) do |hearing, result|
        result << to_canonical_hash(hearing)
      end
      travel_board = []
      [video_and_co.uniq { |hearing_day| [hearing_day[:scheduled_for].to_date, hearing_day[:room]] }, travel_board]
    end

    def load_days_for_regional_office(regional_office, start_date, end_date)
      video_and_co = VACOLS::CaseHearing.load_days_for_regional_office(regional_office, start_date, end_date)
        .each_with_object([]) do |hearing, result|
        result << to_canonical_hash(hearing)
      end
      travel_board = VACOLS::TravelBoardSchedule.load_days_for_regional_office(regional_office, start_date, end_date)
      [video_and_co, travel_board]
    end

    # STAFF.STC2 is the Travel Board limit for Mon and Fri
    # STAFF.STC3 is the Travel Board limit for Tue, Wed, Thur
    # STAFF.STC4 is the Video limit
    def slots_based_on_type(staff:, type:, date:)
      case type
      when HearingDay::HEARING_TYPES[:central]
        11
      when HearingDay::HEARING_TYPES[:video]
        staff.stc4
      when HearingDay::HEARING_TYPES[:travel]
        (date.monday? || date.friday?) ? staff.stc2 : staff.stc3
      end
    end

    def fetch_hearing_day_slots(regional_office_record, hearing_day)
      # returns the total slots for the hearing day's regional office.
      slots_from_vacols = slots_based_on_type(staff: regional_office_record,
                                              type: hearing_day[:hearing_type],
                                              date: hearing_day[:scheduled_for])
      slots_from_vacols || HearingDocket::SLOTS_BY_TIMEZONE[HearingMapper.timezone(hearing_day[:regional_office])]
    end

    def ro_staff_hash(regional_office_keys)
      ro_staff = VACOLS::Staff.where(stafkey: regional_office_keys)
      ro_staff.reduce({}) { |acc, record| acc.merge(record.stafkey => record) }
    end

    def to_canonical_hash(hearing_day)
      if hearing_day.is_a?(HearingDay)
        return hearing_day.to_hash
      end

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
