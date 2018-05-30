# GenerateHearingDaysSchedule is used to generate hearing days in a
# a data range specified used in Hearing schedule.
#
# It takes account to weekends, holidays and board non-available days before
# creating the hearing days schedule for the board and ROs.

class HearingSchedule::GenerateHearingDaysSchedule

  attr_reader :available_days

  def initialize(start_date, end_date, board_non_availability_days = [])
    @board_non_availability_days = board_non_availability_days
    @holidays = Holidays.between(start_date, end_date, :federal_reserve)
    @available_days = filter_non_available_days(start_date, end_date)
  end

  def filter_non_available_days(start_date, end_date)
    business_days = []
    current_day = start_date

    # assuming all dates provided here are in EST
    while current_day <= end_date
      business_days << current_day unless
        (weekend?(current_day) || holiday?(current_day) || board_not_available?(current_day))
      current_day = current_day + 1.day
    end

    business_days
  end
  
  private

  def weekend?(day)
    day.saturday? || day.sunday?
  end

  def holiday?(day)
    @holidays.find { |holiday| holiday[:date] == day }.present?
  end

  def board_not_available?(day)
    @board_non_availability_days.find { |non_available_day| non_available_day == day }.present?
  end
end
