# GenerateHearingDaysSchedule is used to generate the dates available for RO
# video hearings in a specified date range after filtering out weekends,
# holidays, and board non-availability dates
#

class HearingSchedule::GenerateHearingDaysSchedule
  attr_reader :available_days
  attr_reader :ros

  MULTIPLE_ROOM_ROS = %w(RO17 RO18)
  MULTIPLE_NUM_OF_ROOMS = 2
  DEFAULT_NUM_OF_ROOMS = 1

  def initialize(schedule_period, co_non_availability_days = [], ro_non_available_days = {})
    @amortized = 0
    @co_non_availability_days = co_non_availability_days
    @holidays = Holidays.between(schedule_period.start_date, schedule_period.end_date, :federal_reserve)
    @available_days = filter_non_availability_days(schedule_period.start_date, schedule_period.end_date)
    @ro_non_available_days = ro_non_available_days
    
    # handle RO information
    @ros = assign_ro_hearing_day_allocations(RegionalOffice::CITIES, schedule_period.allocations)
    @ros = filter_non_available_ro_days
    @ros = filter_travel_board_hearing_days(schedule_period.start_date, schedule_period.end_date)
    
    allocate_hearing_days_to_ros(schedule_period.start_date, schedule_period.end_date)
    # binding.pry
    json = @ros.map {|k, v| [k, { hearing_days: v[:allocated_days], allocated_dates: v[:allocated_dates] }] }.to_h.to_json

    File.open("public/temp.json","w") do |f|
      f.write(json)
    end
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

  def distribute(percentage, total)
    real = (percentage * total) + @amortized
    natural = real.round
    @amortized = real - natural
    
    natural
  end

  def sort_months(months)
    i = 0
    j = months.size - 1
    arr = []

    while i < j
      arr << months[i]
      i+= 1

      arr << months[j]
      j-= 1
    end

    arr << months[i] if (months.size % 2 != 0)
    arr
  end

  def evenly_distribute_days(monthly_allocations)
    
    odd_days = monthly_allocations.reduce([]) do |acc, (ro_key, days)|
      acc << ro_key unless days % 2 == 0
      acc
    end

    i = 0
    until i >= (odd_days.size - 1)
      monthly_allocations[odd_days[i]] += 1
      monthly_allocations[odd_days[i + 1]] -= 1
      i += 2
    end
    monthly_allocations 
  end

  def validate_available_days(allocated_days, available_days, num_of_rooms)

    puts allocated_days.values.inject(:+)
    puts available_days.values.inject(:+) * num_of_rooms

    raise "There are not enough available days 
      for the number of allocated days" unless allocated_days.values.inject(:+) <= (available_days.values.inject(:+) * num_of_rooms)

    allocated_days.each_key do |ro_key|
      if allocated_days[ro_key] > (available_days[ro_key] * num_of_rooms)
        diff = allocated_days[ro_key] - available_days[ro_key]
  
        available_days_keys = available_days.keys.sort
        allocated_days_keys = allocated_days.keys.sort
  
        i = 0
        while diff != 0
          puts "#{allocated_days[allocated_days_keys[i]]} #{available_days[available_days_keys[i]]}"
          
          if allocated_days[allocated_days_keys[i]] < available_days[available_days_keys[i]]
            allocated_days[ro_key] -= 1
            allocated_days[available_days_keys[i]] += 1
            diff -= 1
          end

          i = (i >= allocated_days.size - 1) ? 0 : (i + 1)
        end
      end
    end
    allocated_days
  end

  def allocate_hearing_days_to_ros(start_date, end_date)

    # FIX THIS! number of days is incorrect here
    percentages_by_month = (start_date..end_date).group_by { |d| [d.month, d.year] }.map do |group|
      [group[0], ((group.last.last - group.last.first).to_f / 
        (group.last.first.end_of_month - group.last.first.beginning_of_month).to_f) * 100]
    end.to_h

    weight_by_month = percentages_by_month.map {|date, num| [date, (num / percentages_by_month.map {|_k,v| v}.inject(:+)) ] }.to_h
    @amortized = 0
    
    @ros.each_key do |ro_key|
      
      num_allocated_days = weight_by_month.map do |month, weight|
        [month, distribute(weight, @ros[ro_key][:allocated_days])]
      end.to_h

      months = @ros[ro_key][:available_days].group_by { |d| [d.month, d.year] }

      is_num_of_days_avaiable = num_allocated_days.map {|k, v| (months[k].size) * @ros[ro_key][:num_of_rooms] > v }.all?
      num_of_rooms = @ros[ro_key][:num_of_rooms]

      # binding.pry if ro_key == "RO18" or ro_key == "RO17"

      resorted_months = sort_months(months.keys).map {|month| [month, num_allocated_days[month]]}.to_h
      binding.pry
      evenly_resorted_months = validate_available_days(evenly_resorted_months, months.map{|k,v| [k, v.size]}.to_h, num_of_rooms) 
      evenly_resorted_months = (num_of_rooms % 2 == 0) ? evenly_distribute_days(resorted_months) : resorted_months

      months = months.map do |ro_key, dates|
        [ro_key, dates.shuffle.reduce({}) { |acc, date| acc[date] = []; acc }]
      end.to_h

      if is_num_of_days_avaiable
        index = 0
        while(evenly_resorted_months.values.inject(:+) != 0)
          
          evenly_resorted_months.each_key do |month|
            allocated_days = evenly_resorted_months[month]
            if allocated_days > 0
              if (num_of_rooms < allocated_days)
                months[month][months[month].keys[index]] = num_of_rooms.times.map {|room_num| "room #{room_num + 1}" }
                allocated_days -= num_of_rooms
              else
                months[month][months[month].keys[index]] = allocated_days.times.map {|room_num| "room #{room_num + 1}" }
                allocated_days -= allocated_days
              end
            end

            evenly_resorted_months[month] = allocated_days 
          end

          index += 1
        end
      @ros[ro_key][:allocated_dates] = months.map{ |k,v| v.to_a.sort.to_h  }

      end
    end
  end

  def allocate_hearing_days_to_individual_ro(ro_info, weight_by_month)
    # num_of_months.

    # num_allocated_days = weight_by_month.map do |weight|
    #   distribute(weight, ro_info[:allocated_days])
    # end
    
    # @ros[ro_key][:num_allocated_days] = num_allocated_days

  end

  private

  def assign_ro_hearing_day_allocations(ro_cities, ro_allocations)
    ro_allocations.reduce({}) do |acc, allocation|
      acc[allocation.regional_office] = ro_cities[allocation.regional_office].merge({
        allocated_days: allocation.allocated_days,
        available_days: @available_days,
        num_of_rooms: MULTIPLE_ROOM_ROS.include?(allocation.regional_office) ?
          MULTIPLE_NUM_OF_ROOMS : DEFAULT_NUM_OF_ROOMS 
      })
      acc
    end
  end

  def filter_travel_board_hearing_days(start_date, end_date)
    travel_board_hearing_days = VACOLS::TravelBoardSchedule.load_days_for_range(start_date, end_date)
    tb_master_records = TravelBoardScheduleMapper.convert_from_vacols_format(travel_board_hearing_days)

    tb_master_records.map do |tb_master_record|
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

  # def assign_available_days_to_ros(ro_cities)
  #   ro_cities.each_key { |ro_key| ro_cities[ro_key][:available_days] = @available_days }
  # end

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
      @ros[ro_key][:available_days] -= (@ro_non_available_days[ro_key] || [])
    end
  end
end
