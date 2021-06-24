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
  class NoDaysAvailableForRO < StandardError; end

  attr_reader :available_days, :ros

  CO_DAYS_OF_WEEK = [3].freeze # only create 1 Central docket(Wednesday) per week
  CO_FALLBACK_DAYS_OF_WEEK = [1, 2, 4].freeze # if wednesday is a holiday, pick a another non-holiday starting monday

  def initialize(schedule_period)
    @schedule_period = schedule_period

    @availability_coocurrence = {}
    @co_non_availability_days = []
    @ro_non_available_days = {}
    @ros = {}
    @request_type_allocations = :allocated_days

    extract_non_available_days

    @holidays = Holidays.between(schedule_period.start_date, schedule_period.end_date, :federal_reserve)
    @available_days = filter_non_availability_days(schedule_period.start_date, schedule_period.end_date)

    assign_and_filter_ro_days(schedule_period)
  end

  # {"RO44"=>
  #   {:state=>"CA",
  #   :city=>"Los Angeles",
  #   :hold_hearings=>true,
  #   :timezone=>"America/Los_Angeles",
  #   :facility_locator_id=>"vba_344",
  #   :label=>"Los Angeles regional office",
  #   :alternate_locations=>nil,
  #   :allocated_days=>0.0,
  #   :allocated_days_without_room=>53.0,
  #   :available_days=>["Thu, 01 Apr 2021", "Fri, 02 Apr 2021"],
  #   :allocated_dates=>{[4, 2021]=>{Thu, 01 Apr 2021=>[{:room_num=>nil}]}, [5, 2021]=>{}, [6, 2021]=>{}}}}
  def allocation_results
    # Return the list of ROs containing the hearing days per date
    @ros
  end

  def allocate_hearing_days_to_ros(request_type_allocations = :allocated_days)
    @request_type_allocations = request_type_allocations

    # Add up all the hearing days we need to distribute for the request type
    days_to_allocate = @ros.values.pluck(@request_type_allocations).sum.to_i

    # Create a lookup table of available days to track the number of allocations per date
    available_days = @available_days.product([0]).to_h

    # Apply the initial sort to the RO list
    ro_list = sort_ro_list(@ros.values)

    # Distribute all of the hearing days to each RO in the list
    allocate_hearing_days(days_to_allocate, ro_list, available_days)
  end

  #
  # Start CO algorithm
  #
  def generate_co_hearing_days_schedule
    co_schedule = []
    co_schedule_args = {
      request_type: HearingDay::REQUEST_TYPES[:central],
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

  #
  # Video/Virtual docket day helper functions
  #
  def allocate_hearing_days(days_to_allocate, ro_list, available_days)
    days_to_allocate.times do |index|
      # Find the next RO and hearing day
      available_ro_and_day = get_ro_for_hearing_day(available_days, ro_list, index)

      # Extract the hearing day and RO
      hearing_day = available_ro_and_day.first
      ro = available_ro_and_day.last

      # Add the hearing day to this RO
      docket_type = (@request_type_allocations == :allocated_days) ? :video : :virtual
      @ros[ro[:ro_key]][:allocated_dates][[hearing_day.month, hearing_day.year]][hearing_day]
        .push(docket_type: docket_type)

      # Decrement the requested days for this RO
      ro[@request_type_allocations] -= 1

      # Increase the lookup table value for this date
      available_days[hearing_day] += 1

      # Move the selected RO to last and remove if it has no more requests
      ro_list = sort_ro_list(ro_list, ro)
    end
  end

  # :reek:FeatureEnvy
  def sort_ro_list(ro_list, ro_info = {})
    # Remove any ROs that don't have any allocation requested
    ros_with_request = ro_list.reject { |ro| ro[@request_type_allocations].to_i == 0 }

    # If we are shuffling the list, move the first element to the last
    if ro_info.any? && ros_with_request.pluck(:ro_key).include?(ro_info[:ro_key])
      ros_with_request.push(ros_with_request.delete_at(ros_with_request.index(ro_info)))
    else
      # Sort the list so the RO with the fewest requests is first
      ros_with_request.sort_by { |ro| ro[@request_type_allocations] }
    end
  end

  def get_ro_for_hearing_day(available_days, ro_list, index)
    hearing_day_index = index

    # If the index is out of bounds circle the array back to index 0 to get the next index
    if hearing_day_index >= @available_days.count
      hearing_day_index -= ((hearing_day_index / available_days.count) * available_days.count)
    end

    # Set the hearing day based on the index
    hearing_day = available_days.keys[hearing_day_index]

    # Check if there is an available Regional office for this day
    ro = get_next_available_ro(ro_list, hearing_day)

    # Move to the next hearing day of no ROs are available
    if ro.nil?
      get_ro_for_hearing_day(available_days, ro_list, index + 1)
    else
      [hearing_day, ro]
    end
  end

  def get_next_available_ro(ro_list, hearing_day)
    # Select only ROs that are available for this day
    ros_for_hearing_day = ro_list.select { |ro| ro[:available_days].include?(hearing_day) }

    # Reject any ROs that have greater than 1 day difference between days scheduled per daye
    least_scheduled_ros = ros_for_hearing_day.reject { |ro| check_even_distribution(ro).count > 1 }

    # If there are no ROs that have 1 day difference, use RO with the minimum days scheduled
    if least_scheduled_ros.count == 0
      ros_for_hearing_day.min_by { |ro| allocated_for_hearing_day?(ro, hearing_day) }
    else
      least_scheduled_ros.min_by { |ro| allocated_for_hearing_day?(ro, hearing_day) }
    end
  end

  def get_all_days_for_ro(ro_info)
    ro_info[:allocated_dates].values.inject(&:merge).values
  end

  def check_even_distribution(ro_info)
    get_all_days_for_ro(ro_info).map { |day| day.select { |room| room[:room_num].nil? } }.map(&:count).uniq
  end

  def check_total_allocations(ro_info)
    get_all_days_for_ro(ro_info).map(&:count).sum
  end

  def allocated_for_hearing_day?(ro_info, hearing_day)
    allocations = ro_info[:allocated_dates].values.inject(&:merge)[hearing_day].select { |room| room[:room_num].nil? }
    allocations.count
  end

  #
  # Initialization functions
  #

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
  #  },
  #  "RO03"=> ...
  # }
  #
  def assign_and_filter_ro_days(schedule_period)
    assign_ro_hearing_day_allocations(RegionalOffice.ros_with_hearings, schedule_period.allocations)
    filter_non_available_ro_days # modifies @ros in-place
    filter_travel_board_hearing_days(schedule_period.start_date, schedule_period.end_date)
    group_availability_coocurrence
    group_monthly_available_dates
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

  def group_availability_coocurrence
    # counts number of ROs available on each day and put them in hash
    # Example:
    #  {
    #    Tue, 05 Jan 2021=>45,
    #    Wed, 06 Jan 2021=>47,
    #    ...
    #  }
    @availability_coocurrence = @ros.inject({}) do |availability, (_ro_key, ro_details)|
      ro_details[:available_days].each do |date|
        availability[date] ||= 0
        availability[date] += 1
      end
      availability
    end
  end

  def group_monthly_available_dates
    @ros.each_key do |ro_key|
      # Ex, {[1, 2021]=>[Tue, 05 Jan 2021, Wed, 06 Jan 2021...], [2, 2021]=> [Mon, 01 Feb 2021, Tue, 02 Feb 2021,..]}
      monthly_available_dates = group_dates_by_month(@ros[ro_key][:available_days])

      # For available days in each month, sort the available days in ascending order of least co-occurrences
      # and iterate through each date to set an empty array.
      # Example:
      # {
      #   "RO01": {[1, 2021]=> {Tue, 05 Jan 2021=>[], Fri, 29 Jan 2021=>[],...}},
      #    ...
      # }
      @ros[ro_key][:allocated_dates] = monthly_available_dates.map do |month, available_dates|
        [month, dates_sorted_and_formatted(available_dates)]
      end.to_h
    end
  end

  def dates_sorted_and_formatted(dates)
    sorted_dates = dates.sort_by { |date| @availability_coocurrence[date] }
    sorted_dates.reduce({}) do |formatted_dates, date|
      formatted_dates[date] = []
      formatted_dates
    end
  end

  # groups dates of each month from an array of dates
  # {[1, 2018] => [Tue, 02 Jan 2018, Thu, 04 Jan 2018], [2, 2018] => [Thu, 01 Feb 2018] }
  def group_dates_by_month(dates)
    dates.group_by { |date| [date.month, date.year] }
  end

  # Initialize allocated_days, available_days for each RO
  def assign_ro_hearing_day_allocations(ro_cities, ro_allocations)
    @ros = ro_allocations.reduce({}) do |acc, allocation|
      ro_key = (allocation.regional_office == "NVHQ") ? HearingDay::REQUEST_TYPES[:virtual] : allocation.regional_office

      acc[allocation.regional_office] = ro_cities[ro_key].merge(
        ro_key: allocation.regional_office,
        allocated_days: allocation.allocated_days,
        allocated_days_without_room: allocation.allocated_days_without_room,
        available_days: @available_days,
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
