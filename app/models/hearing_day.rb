# Class to coordinate interactions between controller
# and repository class. Eventually may persist data to
# Caseflow DB. For now all schedule data is sent to the
# VACOLS DB (Aug 2018 implementation).
class HearingDay
  HEARING_TYPES = {
    video: "V",
    travel: "T",
    central_office: "C"
  }.freeze

  class << self
    def create_hearing_day(hearing_hash)
      HearingDayRepository.create_vacols_hearing!(hearing_hash)
    end

    def update_hearing_day(hearing, hearing_hash)
      HearingDayRepository.update_vacols_hearing!(hearing, hearing_hash)
    end

    def load_days(start_date, end_date, regional_office = nil)
      if regional_office.nil?
        HearingDayRepository.load_days_for_range(start_date, end_date)
      else
        HearingDayRepository.load_days_for_regional_office(regional_office, start_date, end_date)
      end
    end

    def find_hearing_day(hearing_type, hearing_key)
      HearingDayRepository.find_hearing_day(hearing_type, hearing_key)
    end
  end
end
