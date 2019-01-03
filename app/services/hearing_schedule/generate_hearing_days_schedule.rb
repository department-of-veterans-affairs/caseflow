# GenerateHearingDaysSchedule is used to generate the dates available for RO
# video hearings in a specified date range after filtering out weekends,
# holidays, and board non-availability dates
#

class HearingSchedule::GenerateHearingDaysSchedule
  include HearingSchedule::RoAllocation
  include HearingSchedule::RoDistribution

  class NoDaysAvailableForRO < StandardError; end

  attr_reader :available_days, :ros

  MAX_NUMBER_OF_DAYS_PER_DATE = 12
  BVA_VIDEO_ROOMS = [1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13].freeze

  MAX_ITERATIONS = 100

  def initialize(schedule_period)
    @amortized = 0
    @co_non_availability_days = []
    @ro_non_available_days = {}
    @schedule_period = schedule_period
    extract_non_available_days

    @holidays = Holidays.between(schedule_period.start_date, schedule_period.end_date, :federal_reserve)
    @available_days = filter_non_availability_days(schedule_period.start_date, schedule_period.end_date)

    assign_and_filter_ro_days(schedule_period)
  end

  def extract_non_available_days
    @schedule_period.non_availabilities.each do |non_availability|
      obj_id = non_availability.object_identifier

      if non_availability.instance_of? CoNonAvailability
        @co_non_availability_days << non_availability
      elsif non_availability.instance_of? RoNonAvailability
        @ro_non_available_days[obj_id] ||= []
        @ro_non_available_days[obj_id] << non_availability
      end
    end
  end

  def assign_and_filter_ro_days(schedule_period)
    @ros = assign_ro_hearing_day_allocations(RegionalOffice.ros_with_hearings, schedule_period.allocations)
    filter_non_available_ro_days
    @ros = filter_travel_board_hearing_days(schedule_period.start_date, schedule_period.end_date)
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

  # Distributes the allocated days through out the scheduled period months based
  # on the weights (weights are calcuated based on the number of days in that period
  # for the month).
  #
  # Decimal values are currenly converted to a full day for allocated days. 118.5 -> 119
  #
  # Schedule period of (2018-Apr-01, 2018-Sep-30), allocated_days of (118.0) returns ->
  #   {[4, 2018]=>20, [5, 2018]=>19, [6, 2018]=>20, [7, 2018]=>20, [8, 2018]=>19, [9, 2018]=>20}
  #
  def monthly_distributed_days(allocated_days)
    monthly_percentages = self.class.montly_percentage_for_period(@schedule_period.start_date,
                                                                  @schedule_period.end_date)
    self.class.weight_by_percentages(monthly_percentages).map do |month, weight|
      [month, distribute(weight, allocated_days)]
    end.to_h
  end

  def allocate_hearing_days_to_ros
    sorted_ros = sort_ros_by_rooms_and_allocated_days

    loop do
      @ros = sorted_ros.transform_values(&:clone)
      result = allocate_hearing_days_loop
      return result if result
    end
  end

  def sort_ros_by_rooms_and_allocated_days
    @ros.sort_by do |_k, v|
      v[:allocated_days].to_f / v[:num_of_rooms] / v[:available_days].count
    end.reverse.to_h
  end

  private

  def allocate_hearing_days_loop
    @date_allocated = {}
    @amortized = 0

    ros = @ros.each_key do |ro_key|
      allocate_all_ro_monthly_hearing_days(ro_key)
    end

    return ros
  rescue HearingSchedule::Errors::NotEnoughAvailableDays => e
    @iterations ||= 0
    @iterations += 1
    return if @iterations < MAX_ITERATIONS
    raise e
  end

  def allocate_all_ro_monthly_hearing_days(ro_key)
    grouped_monthly_avail_dates = group_dates_by_month(@ros[ro_key][:available_days])
    @ros[ro_key][:allocated_dates] = self.class.shuffle_grouped_monthly_dates(grouped_monthly_avail_dates)
    assign_hearing_days(ro_key)
    add_allocated_days_and_format(ro_key)
  end

  def assign_hearing_days(ro_key)
    i = 0
    date_index = 0

    monthly_allocations = allocations_by_month(ro_key)

    # Keep allocating the days until all monthly allocations are 0
    while i < 10 && monthly_allocations.values.inject(:+) != 0
      i += 1
      allocate_hearing_days_to_individual_ro(
        ro_key,
        monthly_allocations,
        date_index
      )
      date_index += 1
    end
  end

  def allocated_days_for_ro(ro_key)
    @ros[ro_key][:allocated_days].ceil
  end

  def allocations_by_month(ro_key)
    # raise error if there are not enough available days
    verify_total_available_days(ro_key)

    self.class.validate_and_evenly_distribute_monthly_allocations(
      @ros[ro_key][:allocated_dates],
      monthly_distributed_days(allocated_days_for_ro(ro_key)),
      @ros[ro_key][:num_of_rooms]
    )
  end

  def get_max_hearing_days_assignments(ro_key)
    @ros[ro_key][:available_days].count * @ros[ro_key][:num_of_rooms]
  end

  def verify_total_available_days(ro_key)
    max_allocation = get_max_hearing_days_assignments(ro_key)

    unless allocated_days_for_ro(ro_key).to_i <= max_allocation
      fail HearingSchedule::Errors::NotEnoughAvailableDays.new(
        "#{ro_key} can only hold #{max_allocation} hearing days.",
        ro_key: ro_key, max_allocation: max_allocation
      )
    end
  end

  def add_allocated_days_and_format(ro_key)
    @ros[ro_key][:allocated_dates] = @ros[ro_key][:allocated_dates].reduce({}) do |acc, (k, v)|
      acc[k] = v.to_a.sort.to_h
      acc
    end
  end

  # groups dates of each month from an array of dates
  # {[1, 2018] => [Tue, 02 Jan 2018, Thu, 04 Jan 2018], [2, 2018] => [Thu, 01 Feb 2018] }
  def group_dates_by_month(dates)
    dates.group_by { |d| [d.month, d.year] }
  end

  # allocated hearing days for each RO
  #
  # @ros[ro_key][:allocated_dates]: is a hash with months as keys and date has with rooms array value
  # as values.
  #
  # rooms array is initally empty.
  #
  # Sample @ros[ro_key][:allocated_dates] -> {[1, 2018]=> {Thu, 04 Jan 2018=>[], Tue, 02 Jan 2018=>[]}}
  #
  def allocate_hearing_days_to_individual_ro(ro_key, monthly_allocations, date_index)
    grouped_shuffled_monthly_dates = @ros[ro_key][:allocated_dates]

    # looping through all the monthly allocations
    # and assigning rooms to the datess
    monthly_allocations.each_key do |month|
      next if allocation_not_possible?(grouped_shuffled_monthly_dates, monthly_allocations, month)

      allocated_days = monthly_allocations[month]
      monthly_date_keys = (grouped_shuffled_monthly_dates[month] || {}).keys
      num_of_rooms = @ros[ro_key][:num_of_rooms]

      if allocated_days > 0 &&
         grouped_shuffled_monthly_dates[month][monthly_date_keys[date_index]]

        @date_allocated[monthly_date_keys[date_index]] ||= 0
        rooms_to_allocate = get_num_of_rooms_to_allocate(monthly_date_keys[date_index],
                                                         num_of_rooms, allocated_days,
                                                         grouped_shuffled_monthly_dates[month])
        grouped_shuffled_monthly_dates[month][monthly_date_keys[date_index]] =
          get_room_numbers(monthly_date_keys[date_index], rooms_to_allocate)
        allocated_days -= rooms_to_allocate
        remove_available_day_from_ros(monthly_date_keys[date_index])
      end

      monthly_allocations[month] = allocated_days
    end
    @ros[ro_key][:allocated_dates] = grouped_shuffled_monthly_dates
  end

  def remove_available_day_from_ros(date)
    if @date_allocated[date] >= MAX_NUMBER_OF_DAYS_PER_DATE
      @ros.each do |k, v|
        @ros[k][:available_days] -= [date] if !v[:assigned]
      end
    end
  end

  def allocation_not_possible?(grouped_shuffled_monthly_dates, monthly_allocations, month)
    grouped_shuffled_monthly_dates[month].nil? || monthly_allocations[month] == 0
  end

  def any_other_days_a_better_fit?(monthly_grouped_days, num_of_rooms)
    monthly_grouped_days.any? do |_k, v|
      (v.length + num_of_rooms) <= MAX_NUMBER_OF_DAYS_PER_DATE
    end
  end

  def get_num_of_rooms_to_allocate(date, num_of_rooms, allocated_days, monthly_grouped_days)
    num_left_to_max = MAX_NUMBER_OF_DAYS_PER_DATE - @date_allocated[date]

    if num_of_rooms > num_left_to_max
      if any_other_days_a_better_fit?(monthly_grouped_days, num_of_rooms)
        return 0
      end
      return num_left_to_max
    else
      (num_of_rooms <= allocated_days) ? num_of_rooms : allocated_days
    end
  end

  def get_room_numbers(date, num_of_rooms)
    Array.new(num_of_rooms) do |_room_num|
      @date_allocated[date] ||= 0
      value = { room_num: BVA_VIDEO_ROOMS[@date_allocated[date]] }
      @date_allocated[date] += 1
      value
    end
  end

  def distribute(percentage, total)
    real = (percentage * total) + @amortized
    natural = real.round
    @amortized = real - natural

    natural
  end

  def assign_ro_hearing_day_allocations(ro_cities, ro_allocations)
    ro_allocations.reduce({}) do |acc, allocation|
      acc[allocation.regional_office] = ro_cities[allocation.regional_office].merge(
        allocated_days: allocation.allocated_days,
        available_days: @available_days,
        num_of_rooms: get_num_of_rooms(allocation.regional_office)
      )
      acc
    end
  end

  def get_num_of_rooms(ro)
    if RegionalOffice::MULTIPLE_ROOM_ROS.include?(ro)
      RegionalOffice::MULTIPLE_NUM_OF_RO_ROOMS
    else
      RegionalOffice::DEFAULT_NUM_OF_RO_ROOMS
    end
  end

  def filter_travel_board_hearing_days(start_date, end_date)
    travel_board_hearing_days = VACOLS::TravelBoardSchedule.load_days_for_range(start_date, end_date)
    tb_master_records = TravelBoardScheduleMapper.convert_from_vacols_format(travel_board_hearing_days)

    tb_master_records.select { |tb_master_record| @ros.keys.include?(tb_master_record[:ro]) }
      .map do |tb_master_record|
        tb_days = (tb_master_record[:start_date]..tb_master_record[:end_date]).to_a
        @ros[tb_master_record[:ro]][:available_days] -= tb_days
      end
    @ros
  end

  def weekend?(day)
    day.saturday? || day.sunday?
  end

  def holiday?(day)
    @holidays.find { |holiday| holiday[:date] == day }.present?
  end

  def co_not_available?(day)
    @co_non_availability_days.find { |non_availability_day| non_availability_day.date == day }.present?
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
  # fails with NoDaysAvailableForRO
  #   fails if there are no available days for a RO
  #
  def filter_non_available_ro_days
    get_non_available_days = lambda { |ro_key|
      @ro_non_available_days[ro_key] ? @ro_non_available_days[ro_key].map(&:date) : []
    }

    @ros.each_key do |ro_key|
      @ros[ro_key][:available_days] -= get_non_available_days.call(ro_key)
      fail NoDaysAvailableForRO, "No available days for #{ro_key}" if @ros[ro_key][:available_days].empty?
    end
  end
end
