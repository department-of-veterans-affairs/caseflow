# frozen_string_literal: true

##
# GenerateHearingDaysSchedule is used to generate the dates available for RO
# video hearings and CO hearings in a specified date range after filtering out weekends,
# holidays, and board non-availability dates. Full details of the algorithm can be
# found `HearingSchedule.md` in Appeals-team repo (link: https://github.com/department-of-veterans-affairs/appeals-team/
# blob/master/Project%20Folders/Caseflow%20Projects/Hearings/Hearing%20Schedule/Tech%20Specs/HearingSchedule.md).
# WIKI : https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#build-hearing-schedule
##
class HearingSchedule::GenerateHearingDaysSchedule
  include HearingSchedule::RoAllocation
  include HearingSchedule::RoDistribution

  class NoDaysAvailableForRO < StandardError; end

  attr_reader :available_days, :ros

  BVA_VIDEO_ROOMS = Constants::HEARING_ROOMS_LIST.keys.map(&:to_i).freeze
  MAX_NUMBER_OF_DAYS_PER_DATE = BVA_VIDEO_ROOMS.size

  CO_DAYS_OF_WEEK = [3].freeze # only create 1 Central docket(Wednesday) per week
  CO_FALLBACK_DAYS_OF_WEEK = [1, 2, 4].freeze # if wednesday is a holiday, pick a another non-holiday starting monday

  def initialize(schedule_period)
    @schedule_period = schedule_period

    @amortized = 0
    @availability_coocurrence = {}
    @co_non_availability_days = []
    @date_allocated = {}
    @number_to_allocate = 1
    @ro_non_available_days = {}
    @ros = {}
    @with_rooms = true

    extract_non_available_days

    @holidays = Holidays.between(schedule_period.start_date, schedule_period.end_date, :federal_reserve)
    @available_days = filter_non_availability_days(schedule_period.start_date, schedule_period.end_date)

    assign_and_filter_ro_days(schedule_period)
  end

  # Extract non-available days for RO and CO from CoNonAvailability and RoNonAvailability objects
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

  # Sets @ros which is later in the algo; @ros is a hash with ro id (e.g "RO01") as key
  # Example:
  # {
  #  "RO49"=>
  #  {
  #    :state=>"TX", :timezone=>"America/Chicago", :city=>"Waco", :hold_hearings=>true, :label=>"Waco regional office",
  #    :facility_locator_id=>"vba_349", :alternate_locations=>["vba_349i"],
  #    :allocated_days=>57.0,
  #    :available_days=> [Tue, 05 Jan 2021, Wed, 06 Jan 2021...],
  #    :num_of_rooms => 1
  #  },
  #  "RO03"=> ...
  # }
  #
  def assign_and_filter_ro_days(schedule_period)
    @ros = assign_ro_hearing_day_allocations(RegionalOffice.ros_with_hearings, schedule_period.allocations)
    filter_non_available_ro_days # modifies @ros in-place
    @ros = filter_travel_board_hearing_days(schedule_period.start_date, schedule_period.end_date)
  end

  # Total available days; filtering weekends, holidays and board non-available days
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
  # Schedule period of (2021-Jan-01, 2021-Mar-31), allocated_days of (54.0) returns ->
  #    {[1, 2021]=>18, [2, 2021]=>18, [3, 2021]=>18}
  #
  def monthly_distributed_days(allocated_days)
    # Ex, {[1, 2021]=>100.0, [2, 2021]=>100.0, [3, 2021]=>100.0}
    monthly_percentages = self.class.montly_percentage_for_period(@schedule_period.start_date,
                                                                  @schedule_period.end_date)
    # weight_by_percentages =>
    #   Ex, {[1, 2021]=>0.3333333333333333, [2, 2021]=>0.3333333333333333, [3, 2021]=>0.3333333333333333}
    self.class.weight_by_percentages(monthly_percentages).map do |month, weight|
      [month, distribute(weight, allocated_days)]
    end.to_h
  end

  # Starting place of the algo to assign hearing days to RO taking into account whether to constrain by room
  def allocate_hearing_days_to_ros(with_rooms = true)
    # Define an instance variable to flag whether to add the room constraint per hearing day
    @with_rooms = with_rooms

    # Sort the ROs by the number of rooms and allocated days
    @ros = sort_ros_by_rooms_and_allocated_days

    # Perform the hearing day distribution algorithm
    do_allocate_hearing_days
  end

  # Sort ROs in descending order of the highest ratio of allocated days to rooms and available days
  # (i.e. the most "booked" ROs)
  def sort_ros_by_rooms_and_allocated_days
    @ros.sort_by do |_k, v|
      v[:allocated_days].to_f / v[:num_of_rooms] / v[:available_days].count
    end.reverse.to_h
  end

  def generate_co_hearing_days_schedule
    co_schedule = []
    co_schedule_args = {
      request_type: HearingDay::REQUEST_TYPES[:central],
      room: "2",
      bva_poc: "CAROL COLEMAN-DEW"
    }

    (@schedule_period.start_date..@schedule_period.end_date).each do |scheduled_for|
      # if CO_DAYS_OF_WEEK falls on an invalid day, pick a day of the week that is valid
      if CO_DAYS_OF_WEEK.include?(scheduled_for.cwday) && weekend_or_holiday_or_not_available?(scheduled_for)
        fallback_date_for_co = get_fallback_date_for_co(
          scheduled_for, @schedule_period.start_date, @schedule_period.end_date
        )
        if fallback_date_for_co
          co_schedule.push(**co_schedule_args, scheduled_for: fallback_date_for_co)
        end
      else
        next unless valid_day_to_schedule_co(scheduled_for)

        co_schedule.push(**co_schedule_args, scheduled_for: scheduled_for)
      end
    end
    co_schedule
  end

  private

  # Method that encapsulates the allocation of hearing days to ROs
  def do_allocate_hearing_days
    @date_allocated = {}
    @amortized = 0

    # counts number of ROs available on each day and put them in hash
    # Example:
    #  {
    #    Tue, 05 Jan 2021=>45,
    #    Wed, 06 Jan 2021=>47,
    #    ...
    #  }
    @availability_coocurrence = @ros.inject({}) do |h, (_k, v)|
      v[:available_days].each do |date|
        h[date] ||= 0
        h[date] += 1
      end
      h
    end

    ros = @ros.each_key do |ro_key|
      allocate_all_ro_monthly_hearing_days(ro_key)
    end

    ros
  end

  # Allocate RO for each month within the schedule period
  def allocate_all_ro_monthly_hearing_days(ro_key)
    # Ex, {[1, 2021]=>[Tue, 05 Jan 2021, Wed, 06 Jan 2021...], [2, 2021]=> [Mon, 01 Feb 2021, Tue, 02 Feb 2021,..]}
    grouped_monthly_avail_dates = group_dates_by_month(@ros[ro_key][:available_days])

    # For available days in each month, sort the available days in ascending order of least co-occurrences
    # and iterate through each date to set an empty array.
    # Example:
    # {
    #   "RO01": {[1, 2021]=> {Tue, 05 Jan 2021=>[], Fri, 29 Jan 2021=>[],...}},
    #    ...
    # }
    @ros[ro_key][:allocated_dates] = grouped_monthly_avail_dates.map do |k, dates|
      [k, dates.sort_by { |date| @availability_coocurrence[date] }.reduce({}) do |acc, date|
        acc[date] = []
        acc
      end]
    end.to_h

    assign_hearing_days(ro_key)
    add_allocated_days_and_format(ro_key) # sort dates chronologically per month (restore order from before above^ sort)
  end

  def assign_hearing_days(ro_key)
    # date_index and i are always the same...
    # i is only used as a counter
    # date_index is passed to allocate_hearing_days_to_individual_ro
    i = 0
    date_index = 0

    # {[4, 2018]=>20, [9, 2018]=>20..}
    monthly_allocations = allocations_by_month(ro_key)

    # Assign rooms differently if we are not constraining by room
    if @with_rooms == false
      assign_hearing_days_without_rooms_to_individual_ro(ro_key, monthly_allocations)
    else
      # iterate over each day starting from the first of the month till the 31st (max day a month can have)
      # Allocate max number of days for the 1st of each month based on remaining monthly allocations for that month
      # and available days
      # Allocate max number of days for the 2nd of each month...
      # Allocate max number of days for the 3rd of each month...
      # ...until we go through all days in a month (31) or exhaust total allocations
      # results are stored in @ros[ro_key][:allocated_dates]
      while i < 31 && monthly_allocations.values.inject(:+) != 0
        i += 1
        allocate_hearing_days_to_individual_ro(
          ro_key,
          monthly_allocations,
          date_index
        )
        date_index += 1
      end
    end
  end

  # Method to assign hearing days for each roomless hearing day requested
  def assign_hearing_days_without_rooms_to_individual_ro(ro_key, monthly_allocations)
    # Loop the available alocations for this RO
    monthly_allocations.each do |month, allocated_days|
      # Get the available days for this RO this month
      available_days = @ros[ro_key][:allocated_dates][month]

      # Skip if there are no requested days or available days
      next if available_days.nil? || available_days&.count == 0 || allocated_days == 0

      # Determine the difference between the requested and available to use as an offset when requested is greater
      remaining = allocated_days % available_days.count

      # Determine the divisor to use with the offset calculation
      offset_divisor = (allocated_days < available_days.count) ? allocated_days : remaining

      # Determine whether there is an offset by dividing available by the above calculation
      offset = (remaining == 0) ? 0 : available_days.count / offset_divisor

      # Initialize the calculated index
      offset_index = 0

      # Set the number allocated to 1 initially
      @number_to_allocate = 1

      # Loop through the requested number to distribute the hearing days evenly
      allocated_days.times do
        # Check whether we have allocated the number to allocate for each day
        if available_days.values.count { |day| day.count == @number_to_allocate } == available_days.count
          # Update the number to allocate
          @number_to_allocate += 1
        end

        # Determine the index of the date on which we should assign this hearing day
        offset_index = get_index_for_hearing_day(available_days, offset, offset_index)

        # Add a new hearing day at the index that was calcualted above
        available_days[available_days.keys[offset_index]].push(room_num: nil)
      end
    end
  end

  # Gets the hearing day index ensuring an even spread of hearing days
  def get_index_for_hearing_day(available_days, distribution_offset, index)
    # Calculate the offset based on the distribution offset and the current index
    offset = distribution_offset + index

    # Calculate the new index with the offset accounting for when the offset exceeds the available days
    get_index_offset(available_days, offset)
  end

  # Method to get the index offset for an array ensuring we go around the array instead of getting out of bounds
  def get_index_offset(available_days, offset)
    offset_index = offset % available_days.length

    # Check if there is a hearing day already allocated
    if available_days[available_days.keys[offset_index]].count == @number_to_allocate
      # Recursively get the index offset adding 1 until we find a date with fewer hearing days than number to allocate
      get_index_offset(available_days, offset_index + 1)
    else
      # Once we have found an index that has fewer days than needed, return that index
      offset_index
    end
  end

  def allocated_days_for_ro(ro_key)
    @ros[ro_key][:allocated_days].ceil
  end

  # Returns allocations for each month for the RO
  #   Ex, { [1, 2021] => 18, [3, 2021] => 18, [2, 2021] => 18 }
  #
  # monthly_distributed_days => distribute total allocated days to each month
  # Example:
  #   Schedule period of (2021-Jan-01, 2021-Mar-31), allocated_days of (54.0) ->
  #      {[1, 2021]=>18, [2, 2021]=>18, [3, 2021]=>18}
  #
  def allocations_by_month(ro_key)
    # Ignore room constraints if specified
    if @with_rooms == false
      if @ros[ro_key][:available_days].count == 0
        fail HearingSchedule::Errors::NotEnoughAvailableDays.new(
          "No available hearing days for #{ro_key}",
          ro_key: ro_key
        )
      end

      monthly_distributed_days(@ros[ro_key][:allocated_days_without_room].ceil)
    else
      # raise error if there are not enough available video days
      verify_total_available_days(ro_key)

      # Validate the video hearing days and evenly distribute
      self.class.validate_and_evenly_distribute_monthly_allocations(
        @ros[ro_key][:allocated_dates],
        monthly_distributed_days(allocated_days_for_ro(ro_key)),
        @ros[ro_key][:num_of_rooms]
      )
    end
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
    grouped_shuffled_monthly_dates = @ros[ro_key][:allocated_dates] # not actually shuffled!

    # looping through all the monthly allocations
    # and assigning rooms to the dates
    monthly_allocations.each_key do |month|
      # go to next month if this month has nil instead of an array (not possible?) or no allocations for the month
      next if allocation_not_possible?(grouped_shuffled_monthly_dates, monthly_allocations, month)

      allocated_days = monthly_allocations[month] # number of days to allocate for this month
      monthly_date_keys = (grouped_shuffled_monthly_dates[month] || {}).keys # available dates in month to allocate to
      num_of_rooms = @ros[ro_key][:num_of_rooms]

      # both conditions are always true b/c allocation_not_possible checks both.........
      if allocated_days > 0 &&
         grouped_shuffled_monthly_dates[month][monthly_date_keys[date_index]]

        @date_allocated[monthly_date_keys[date_index]] ||= 0
        # how many rooms can we allocate for this date
        rooms_to_allocate = get_num_of_rooms_to_allocate(monthly_date_keys[date_index], # date at date_index
                                                         num_of_rooms, allocated_days,
                                                         grouped_shuffled_monthly_dates[month])
        # assign room numbers for number of rooms [docket days] we can allocate on this date
        grouped_shuffled_monthly_dates[month][monthly_date_keys[date_index]] =
          get_room_numbers(monthly_date_keys[date_index], rooms_to_allocate)
        # we've allocated "rooms_to_allocate" days, remove them from total left to allocate
        allocated_days -= rooms_to_allocate
        # remove date from set of available dates for all ROs if we've hit the max allocations per date
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

  # how many rooms should we allocate for this date based on
  # - we cannot exceed the number of max allocations per date
  # - we cannot exceed the number of rooms this RO has
  # - we cannot exceed the number of days we need to allocate
  # return whichever is smallest of the three (or 0 if there's a better date)
  def get_num_of_rooms_to_allocate(date, num_of_rooms, allocated_days, monthly_grouped_days)
    # how many can we still allocate for this date?
    num_left_to_max = MAX_NUMBER_OF_DAYS_PER_DATE - @date_allocated[date]

    if num_of_rooms > num_left_to_max # if the RO has more rooms than allocations, try to allocate to it
      # is there any date that has less allocations than the total number of allocations per date?
      if any_other_days_a_better_fit?(monthly_grouped_days, num_of_rooms)
        return 0 # do not allocate ANY rooms for this date b/c better one exists
      end

      num_left_to_max # allocate as many as possible (all remaining for this date)
    else
      # either allocate however many rooms the RO has or simply the number of days to allocate if that is smaller
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

  # total allocated days for RO are distributed per month based on monthly percentage
  # allocated days for month may not be integer, round allocated days, save leftover in amortized to distribute later
  def distribute(percentage, total)
    real = (percentage * total) + @amortized
    natural = real.round
    @amortized = real - natural

    natural
  end

  # Initialize allocated_days, available_days, and num_of_rooms for each RO
  def assign_ro_hearing_day_allocations(ro_cities, ro_allocations)
    ro_allocations.reduce({}) do |acc, allocation|
      ro_key = (allocation.regional_office == "NVHQ") ? HearingDay::REQUEST_TYPES[:virtual] : allocation.regional_office

      acc[allocation.regional_office] = ro_cities[ro_key].merge(
        allocated_days: allocation.allocated_days,
        allocated_days_without_room: allocation.allocated_days_without_room,
        available_days: @available_days,
        num_of_rooms: RegionalOffice.new(ro_key).rooms,
        number_of_slots: allocation.number_of_slots,
        slot_length_minutes: allocation.slot_length_minutes,
        first_slot_time: allocation.first_slot_time
      )
      acc
    end
  end

  # Gets a list of upcoming travel board hearings for the schedule period and if a RO
  # has any travel days, subtract those days from its available days
  def filter_travel_board_hearing_days(start_date, end_date)
    travel_board_hearing_days = TravelBoardScheduleRepository.load_tb_days_for_range(start_date, end_date)
    tb_hearing_days = TravelBoardScheduleMapper.convert_from_vacols_format(travel_board_hearing_days)

    tb_hearing_days.select { |tb_hearing_day| @ros.key?(tb_hearing_day[:ro]) }
      .map do |tb_hearing_day|
        tb_days = (tb_hearing_day[:start_date]..tb_hearing_day[:end_date]).to_a # travel days have start and end date
        @ros[tb_hearing_day[:ro]][:available_days] -= tb_days
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

  def weekend_or_holiday_or_not_available?(date)
    weekend?(date) || holiday?(date) || co_not_available?(date)
  end

  # pick the first day from fallback days that is valid
  def get_fallback_date_for_co(scheduled_for, start_date, end_date)
    valid_cwday = CO_FALLBACK_DAYS_OF_WEEK.detect do |cwday|
      # i.e, if cwday is 1 and since begining of week is always monday, this will evauluate to monday
      date = scheduled_for.beginning_of_week + (cwday - 1).day

      # fallback date we choose has to valid as well as within the scheduling period range
      !weekend_or_holiday_or_not_available?(date) && date >= start_date && date <= end_date
    end

    valid_cwday ? scheduled_for.beginning_of_week + (valid_cwday - 1).day : nil
  end

  def valid_day_to_schedule_co(scheduled_for)
    CO_DAYS_OF_WEEK.include?(scheduled_for.cwday) && !weekend_or_holiday_or_not_available?(scheduled_for)
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
