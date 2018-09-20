# Hearing Schedule Repository to help build and edit hearing
# master records in VACOLS for Video, TB and CO hearings.
class HearingDayRepository
  class << self
    def create_vacols_hearing!(hearing_hash)
      hearing_hash = HearingDayMapper.hearing_day_field_validations(hearing_hash)
      to_canonical_hash(VACOLS::CaseHearing.create_hearing!(hearing_hash)) if hearing_hash.present?
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
      video_and_co = VACOLS::CaseHearing.load_days_for_range(start_date, end_date)
        .each_with_object([]) do |hearing, result|
        result << to_canonical_hash(hearing)
      end
      travel_board = VACOLS::TravelBoardSchedule.load_days_for_range(start_date, end_date)
      [video_and_co, travel_board]
    end

    def load_days_for_central_office(start_date, end_date)
      video_and_co = VACOLS::CaseHearing.load_days_for_central_office(start_date, end_date)
        .each_with_object([]) do |hearing, result|
        result << to_canonical_hash(hearing)
      end
      travel_board = []
      [video_and_co, travel_board]
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

    def fetch_hearing_days_slots(hearing_days)
      # fetching all the RO keys of the dockets
      regional_office_keys = hearing_days.map { |hearing_day| hearing_day[:regional_office] }

      # fetching data of all dockets staff based on the regional office keys
      ro_staff = VACOLS::Staff.where(stafkey: regional_office_keys)
      ro_staff_hash = ro_staff.reduce({}) { |acc, record| acc.merge(record.stafkey => record) }

      # returns a hash of docket date (string) as key and number of slots for the docket
      # as they key
      hearing_days.each do |hearing_day|
        record = ro_staff_hash[hearing_day[:regional_office]]
        slots_from_vacols = slots_based_on_type(staff: record,
                                                type: hearing_day[:hearing_type],
                                                date: hearing_day[:hearing_date])
        slots_from_timezone = HearingDocket.SLOTS_BY_TIMEZONE[HearingMapper.timezone(hearing_day[:regional_office])]
        slots = slots_from_vacols || slots_from_timezone
        hearing_day[:total_slots] = slots
      end
    end

    def to_canonical_hash(hearing)
      hearing_hash = hearing.as_json.each_with_object({}) do |(k, v), result|
        result[HearingDayMapper::COLUMN_NAME_REVERSE_MAP[k.to_sym]] = v
      end
      hearing_hash.delete(nil)
      values_hash = hearing_hash.each_with_object({}) do |(k, v), result|
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
