# GenerateHearingDaysSchedule is used to generate hearing days between  
#
#

class HearingSchedule::GenerateHearingDaysSchedule

  attr_reader :avaiable_days

  def initialize(start_date, end_date, board_non_availability_days = [])
    @board_non_availability_days = board_non_availability_days
    @holidays = Holidays.between(start_date, end_date, :federal_reserve) 
    @avaiable_days = self.filter_non_available_days(start_date, end_date, board_non_availability_days)
  end

  def filter_non_available_days(start_date, end_date, board_non_availability_days)
    business_days = []
    current_day = start_date

    while current_day <= end_date
      business_days << current_day unless 
        (is_weekend(current_day) || is_holiday(current_day) || is_board_not_available(current_day))
      current_day = current_day + 1.day
    end

    business_days
  end

  def is_weekend(day)
    day.saturday? || day.sunday?
  end

  def is_holiday(day)
    @holidays.find { |holiday| holiday[:date] == day }.present?
  end

  def is_board_not_available(day)
    @board_non_availability_days.find { |non_available_day| non_available_day == day }.present?
  end
end
