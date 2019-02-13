# Utility to create Central Office Hearings in production
# for a specific date range.
# Before running this job verify the parameters with
# the Hearings Management Branch

class GenerateCOHearingDaysSchedule
  # Parameters
  # Days of week to schedule: Mon - Thur
  DAYS_OF_WEEK = [1, 2, 3, 4].freeze

  # CO Blackout Days - Provided by Hearings Management Branch
  # Caseflow Issue #8666
  BLACKOUT_DAYS = [
    Date.new(2019, 4, 18),
    Date.new(2019, 5, 23),
    Date.new(2019, 5, 24),
    Date.new(2019, 5, 27),
    Date.new(2019, 6, 20),
    Date.new(2019, 7, 1),
    Date.new(2019, 7, 2),
    Date.new(2019, 7, 3),
    Date.new(2019, 7, 4),
    Date.new(2019, 7, 5),
    Date.new(2019, 7, 18),
    Date.new(2019, 8, 15),
    Date.new(2019, 8, 30),
    Date.new(2019, 9, 2),
    Date.new(2019, 9, 19)
  ].freeze

  class << self
    def generate_schedule(start_date, end_date)
      (start_date..end_date).each do |scheduled_for|
        next unless valid_day_to_schedule(scheduled_for)

        HearingDay.create_hearing_day(
          scheduled_for: scheduled_for,
          request_type: HearingDay::REQUEST_TYPES[:central],
          room: "2",
          bva_poc: "CAROL COLEMAN-DEW"
        )
      end
    end

    def valid_day_to_schedule(scheduled_for)
      DAYS_OF_WEEK.include?(scheduled_for.cwday) && !BLACKOUT_DAYS.include?(scheduled_for)
    end
  end
end
