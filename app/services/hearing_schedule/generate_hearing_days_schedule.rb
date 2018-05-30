# GenerateHearingDaysSchedule is used to generate hearing days in a
# a data range specified used in Hearing schedule.
#
# It takes account to weekends, holidays and board non-available days before
# creating the hearing days schedule for the board and ROs.

class HearingSchedule::GenerateHearingDaysSchedule
  attr_reader :available_days
  attr_reader :ros

  def initialize(start_date, end_date, board_non_availability_days = [], ro_non_available_days = {})
    @board_non_availability_days = board_non_availability_days
    @ro_non_available_days = ro_non_available_days
    @holidays = Holidays.between(start_date, end_date, :federal_reserve)
    @available_days = filter_non_available_days(start_date, end_date)

    # handle RO information
    @ros = assign_available_days_to_ros(RegionalOffice::CITIES)
    @ros = filter_non_available_ro_days
  end

  def filter_non_available_days(start_date, end_date)
    business_days = []
    current_day = start_date

    # assuming all dates provided here are in EST
    while current_day <= end_date
      business_days << current_day unless
        weekend?(current_day) || holiday?(current_day) || board_not_available?(current_day)
      current_day += 1.day
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

  def assign_available_days_to_ros(ro_cities)
    ro_cities.each { |ro_key, value| ro_cities[ro_key][:available_days] = @available_days }
  end

  # Filters out the non-available RO days from the board available days for
  # each RO.
  #
  # This expects ro_non_available_days to be a hash
  # For example:
  #   {"RO15" => [
  #     Mon, 02 Apr 2018,
  #     Wed, 04 Apr 2018,
  #     Thu, 05 Apr 2018,
  #     Fri, 06 Apr 2018
  #   ]}
  #
  def filter_non_available_ro_days
    @ros.each do |ro_key, value|
      @ros[ro_key][:available_days] = @ros[ro_key][:available_days] - (@ro_non_available_days[ro_key] || [])
    end
  end
end
