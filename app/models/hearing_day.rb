# Class to coordinate interactions between controller
# and repository class. Eventually may persist data to
# Caseflow DB. For now all schedule data is sent to the
# VACOLS DB (Aug 2018 implementation).
class HearingDay
  class << self
    def create_hearing_day(hearing_hash)
      HearingDayRepository.create_vacols_hearing!(hearing_hash)
    end

    def load_days_for_range(start_date, end_date)
      HearingDayRepository.load_days_for_range(start_date, end_date)
    end
  end
end
