# Class to coordinate interactions between controller
# and repository class. Eventually may persist data to
# Caseflow DB. For now all schedule data is sent to the
# VACOLS DB (Aug 2018 implementation).
class HearingDay < ApplicationRecord
  HEARING_TYPES = {
    video: "V",
    travel: "T",
    central: "C"
  }.freeze

  CASEFLOW_SCHEDULE_DATE = Date.new(2019, 3, 31).freeze

  class << self
    def create_hearing_day(hearing_hash)
      if Date.parse(hearing_hash[:hearing_date]) > CASEFLOW_SCHEDULE_DATE
        create(hearing_hash)
      else
        HearingDayRepository.create_vacols_hearing!(hearing_hash)
      end
    end

    def update_hearing_day(hearing, hearing_hash)
      if hearing.class.name === "HearingDay"
        hearing.update(hearing_hash)
      else
        HearingDayRepository.update_vacols_hearing!(hearing, hearing_hash)
      end
    end

    def create_schedule(scheduled_hearings)
      scheduled_hearings.each do |hearing_hash|
        if Date.parse(hearing_hash[:hearing_date]) > CASEFLOW_SCHEDULE_DATE
          create(hearing_hash)
        else
          HearingDay.create_hearing_day(hearing_hash)
        end
      end
    end

    def update_schedule(updated_hearings)
      updated_hearings.each do |hearing_hash|
        hearing_to_update = HearingDay.find_hearing_day(hearing_hash[:hearing_type], hearing_hash[:hearing_key])
        hearing_hash.delete(:hearing_key)
        if hearing_to_update.class.name === "HearingDay"
          hearing_to_update.update(hearing_hash)
        else
          HearingDay.update_hearing_day(hearing_to_update, hearing_hash)
        end
      end
    end

    def load_days(start_date, end_date, regional_office = nil)
      if regional_office.nil?
        HearingDayRepository.load_days_for_range(start_date, end_date)
      else
        HearingDayRepository.load_days_for_regional_office(regional_office, start_date, end_date)
      end
    end

    def find_hearing_day(hearing_type, hearing_key)
      hearing_day = find(hearing_key)
      rescue ActiveRecord::RecordNotFound
        hearing_day = HearingDayRepository.find_hearing_day(hearing_type, hearing_key)
      hearing_day
    end
  end
end
