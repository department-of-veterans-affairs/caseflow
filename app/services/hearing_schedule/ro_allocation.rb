# frozen_string_literal: true

module HearingSchedule::RoAllocation
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    # I don't truly understand the point of this sort.
    # For exmaple,
    # Given months = [[1, 2021], [2, 2021], [3, 2021]], ordered_months = [], i = 0, j = 2
    #  iter 1 => ordered_months = [[1, 2021], [3, 2021]], i=1, j=1; loop ends
    #  after loop => [[1, 2021], [3, 2021], [[2, 2021]]]
    #
    # so [[1, 2021], [2, 2021], [3, 2021]] becomes [[1, 2021], [3, 2021], [[2, 2021]]]
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
    #   { [1, 2021] => 18, [3, 2021] => 18, [2, 2021] => 18 }
    # available_days:
    #   { [1, 2021] => 18, [2, 2021] => 18, [3, 2021] => 18}
    # num_of_rooms: 1
    # returns:
    #   { [1, 2021] => 18, [3, 2021] => 18, [2, 2021] => 18 }
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

        # diff is all days we cannot allocate for this month
        diff = allocated_days[month] - get_available_days(available_days, month) * num_of_rooms
        allocated_days_keys = allocated_days.keys.sort

        # redistribute days that we cannot allocate for this month to other months
        # that still have available days (allocated < available_days*rooms for that month)
        # until all days are distributed
        i = 0
        while diff > 0
          if allocated_days[allocated_days_keys[i]] <
             (get_available_days(available_days, allocated_days_keys[i]) * num_of_rooms) &&
             allocated_days_keys[i] != month

            # subtract single allocation from this month
            allocated_days[month] -= 1
            # add the single allocation to available month
            allocated_days[allocated_days_keys[i]] += 1
            diff -= 1
          end

          # loop back to first month or increment to next month
          # equivalent to i = (i + 1) % allocated_days.size
          i = (i >= allocated_days.size - 1) ? 0 : (i + 1)
        end
      end
      allocated_days # return number of allocated days per month after redistribution
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
      while j < (allocated_days.size * num_of_rooms) # number of months * number of rooms
        i = 0
        until i >= (allocation_keys.size - 1) # while i < (allocated_days.size - 1)
          # iterate over months in pairs
          month = allocation_keys[i]
          next_month = allocation_keys[i + 1]

          # IF month has more available days than allocated AND
          # we can't evenly divide the allocated days for the month by the number of rooms AND
          # the next month has more allocated days than 75% of the month with least allocated days THEN
          # allocate one more day for this month and take one from the next month.
          if (get_available_days(available_days, month) * num_of_rooms) > allocated_days[month] &&
             (allocated_days[month] % num_of_rooms != 0) &&
             (allocated_days[next_month] > (allocated_days.values.min * 0.75))
            allocated_days[month] += 1
            allocated_days[next_month] -= 1
            i += 2
          else
            i += 1 # ELSE proceed to next month pair without re-allocating
          end
        end
        j += 1
      end
      allocated_days
    end

    # Evens out the monthly allocated days that best divide by the number of rooms provided.
    #
    # grouped_monthly_avail_dates:
    #   { [1, 2021] => { Tue, 05 Jan 2021 => [], Tue, 12 Jan 2021 => [],.. }, [2, 2021] => {...} }
    # monthly_allocated_days:
    #   { [1, 2021] => 18, [2, 2021] => 18, [3, 2021] => 18 }
    # num_of_rooms:
    #    1
    #
    # returns:
    #  { [1, 2021] => 18, [3, 2021] => 18, [2, 2021] => 18 }
    #
    def validate_and_evenly_distribute_monthly_allocations(grouped_monthly_avail_dates,
                                                           monthly_allocated_days, num_of_rooms)

      # count the number of available days for each month
      # {[1, 2021]=> {Mon, 04 Jan 2021=>[], ...},...} => {[1, 2021]=>18, [2, 2021]=>18, [3, 2021]=>18}
      available_days = grouped_monthly_avail_dates.map { |k, v| [k, v.size] }.to_h

      # Sorts monthly allocated days
      #
      # monthly_allocated_days.keys => [[1, 2021], [2, 2021], [3, 2021]]
      # sort_monthly_order(monthly_allocated_days.keys) => [[1, 2021], [3, 2021], [[2, 2021]]]
      # resorted_monthly_dates => { [1, 2021] => 18, [3, 2021] => 18, [2, 2021] => 18 }
      resorted_monthly_dates = sort_monthly_order(monthly_allocated_days.keys).map do |month|
        [month, monthly_allocated_days[month]]
      end.to_h

      # the next two function calls modify resorted_monthly_dates in-place!
      # valid_resorted_months == resorted_monthly_dates
      valid_resorted_months = validate_available_days(resorted_monthly_dates, available_days, num_of_rooms)
      distribute_days_evenly(valid_resorted_months, available_days, num_of_rooms)

      # if validations pass => { [1, 2021] => 18, [3, 2021] => 18, [2, 2021] => 18 }
      resorted_monthly_dates
    end
  end
end
