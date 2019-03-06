# frozen_string_literal: true

module HearingSchedule::RoAllocation
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def sort_monthly_order(months)
      i = 0
      j = months.size - 1
      ordered_months = []

      while i < j
        ordered_months << months[i]
        i += 1

        ordered_months << months[j]
        j -= 1
      end

      ordered_months << months[i] if months.size.odd?
      ordered_months
    end

    # Validates the current allocated days based on the available days for each
    # month in the schedule periods. Also evens out the monthly allocated days
    # based on the available days.
    #
    # For Example:
    # allocated days:
    #   { [1, 2018] => 20, [2, 2018] => 10, [6, 2018] => 30 }
    # available_days:
    #   { [1, 2018] => 10, [2, 2018] => 10, [6, 2018] => 10 }
    # num_of_rooms: 2
    # returns:
    #   { [1, 2018] => 20, [2, 2018] => 20, [6, 2018] => 20 }
    #
    # Raises NotEnoughAvailableDays if there not not enough available days based
    # on the allocated days and rooms available.
    #
    def validate_available_days(allocated_days, available_days, num_of_rooms)
      # raise error if there are not enough available days
      verify_total_available_days(allocated_days, available_days, num_of_rooms)

      allocated_days.each_key do |month|
        # skipping if allocated days meets the available days critiera
        next if allocated_days[month] <= (get_available_days(available_days, month) * num_of_rooms)

        diff = allocated_days[month] - get_available_days(available_days, month) * num_of_rooms
        allocated_days_keys = allocated_days.keys.sort

        i = 0
        while diff > 0
          if allocated_days[allocated_days_keys[i]] <
             (get_available_days(available_days, allocated_days_keys[i]) * num_of_rooms) &&
             allocated_days_keys[i] != month

            allocated_days[month] -= 1
            allocated_days[allocated_days_keys[i]] += 1
            diff -= 1
          end

          i = (i >= allocated_days.size - 1) ? 0 : (i + 1)
        end
      end
      allocated_days
    end

    def get_available_days(available_days, month)
      available_days[month] || 0
    end

    def verify_total_available_days(allocated_days, available_days, num_of_rooms)
      fail HearingSchedule::Errors::NotEnoughAvailableDays unless
        allocated_days.values.inject(:+) <= (available_days.values.inject(:+) * num_of_rooms)
    end

    # distributes the hearing days evenly using the number of rooms specified.
    #
    # allocated_days:
    #   [4, 2018] => 11, [9, 2018] => 21, [5, 2018] => 22,
    #     [8, 2018] => 23, [6, 2018] => 21, [7, 2018] => 20
    # available_days:
    #   [4, 2018] => 9, [5, 2018] => 19, [6, 2018] => 19,
    #     [7, 2018] => 17, [8, 2018] => 21, [9, 2018] => 17
    #
    def distribute_days_evenly(allocated_days, available_days, num_of_rooms)
      allocation_keys = allocated_days.keys

      j = 0
      while j < (allocated_days.size * num_of_rooms)
        i = 0
        until i >= (allocation_keys.size - 1)
          month = allocation_keys[i]
          next_month = allocation_keys[i + 1]

          if (get_available_days(available_days, month) * num_of_rooms) > allocated_days[month] &&
             (allocated_days[month] % num_of_rooms != 0) &&
             (allocated_days[next_month] > (allocated_days.values.min * 0.75))
            allocated_days[month] += 1
            allocated_days[next_month] -= 1
            i += 2
          else
            i += 1
          end
        end
        j += 1
      end
      allocated_days
    end

    # Evens out the monthly allocated days that best divide by the number of rooms provided.
    #
    # Monthly allocated days is converted to:
    # {[4, 2018]=>20, [5, 2018]=>19, [6, 2018]=>20, [7, 2018]=>20, [8, 2018]=>19, [9, 2018]=>20}
    #
    # {[4, 2018]=>20, [9, 2018]=>20, [5, 2018]=>20, [8, 2018]=>18, [6, 2018]=>20, [7, 2018]=>20}
    #
    def validate_and_evenly_distribute_monthly_allocations(grouped_monthly_avail_dates,
                                                           monthly_allocated_days, num_of_rooms)
      available_days = grouped_monthly_avail_dates.map { |k, v| [k, v.size] }.to_h

      resorted_monthly_dates = sort_monthly_order(monthly_allocated_days.keys).map do |month|
        [month, monthly_allocated_days[month]]
      end.to_h

      valid_resorted_months = validate_available_days(resorted_monthly_dates, available_days, num_of_rooms)
      distribute_days_evenly(valid_resorted_months, available_days, num_of_rooms)
      resorted_monthly_dates
    end
  end
end
