# GenerateHearingDaysSchedule is used to generate the dates available for RO
# video hearings in a specified date range after filtering out weekends,
# holidays, and board non-availability dates
#

class HearingSchedule::GenerateHearingDaysSchedule
  attr_reader :available_days
  attr_reader :ros

  def initialize(schedule_period, co_non_availability_days = [], ro_non_available_days = {})
    @co_non_availability_days = co_non_availability_days
    @holidays = Holidays.between(schedule_period.start_date, schedule_period.end_date, :federal_reserve)
    @available_days = filter_non_availability_days(schedule_period.start_date, schedule_period.end_date)
    @ro_non_available_days = ro_non_available_days

    # handle RO information
    @ros = assign_available_days_to_ros(RegionalOffice::CITIES)
    @ros = filter_non_available_ro_days
  end

  def filter_non_availability_days(start_date, end_date)
    business_days = []
    current_day = start_date

    while current_day <= end_date
      business_days << current_day unless
        weekend?(current_day) || holiday?(current_day) || co_not_available?(current_day)
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

  def co_not_available?(day)
    @co_non_availability_days.find { |non_availability_day| non_availability_day.date == day }.present?
  end

  def assign_available_days_to_ros(ro_cities)
    ro_cities.each_key { |ro_key| ro_cities[ro_key][:available_days] = @available_days }
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
    @ros.each_key do |ro_key|
      @ros[ro_key][:available_days] = @ros[ro_key][:available_days] - (@ro_non_available_days[ro_key] || [])
    end
  end
end
