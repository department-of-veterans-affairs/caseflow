module HearingSchedule::RoAllocation
  class NotEnoughAvailableDays < StandardError; end

  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods
  end

  module InstanceMethods
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

    def validate_available_days(allocated_days, available_days, num_of_rooms)
      # raise error if there are not enough avaiable days
      fail NotEnoughAvailableDays unless allocated_days.values.inject(:+) <= (available_days.values.inject(:+) * num_of_rooms)

      allocated_days.each_key do |ro_key|
        next unless allocated_days[ro_key] > (available_days[ro_key] * num_of_rooms)
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
      allocated_days
    end

    def distribute_days_evenly(allocated_days, available_days, num_of_rooms)
      allocation_keys = allocated_days.keys
      min_days = allocated_days.values.min * 0.75

      j = 0
      while j < (allocated_days.size * num_of_rooms)
        i = 0
        until i >= (allocation_keys.size - 1)
          if (available_days[allocation_keys[i]] * num_of_rooms) > allocated_days[allocation_keys[i]] &&
             (allocated_days[allocation_keys[i]] % num_of_rooms != 0) &&
             (allocated_days[allocation_keys[i + 1]] > min_days)
            allocated_days[allocation_keys[i]] += 1
            allocated_days[allocation_keys[i + 1]] -= 1
            i += 2
          else
            i += 1
          end
        end
        j += 1
      end
      allocated_days
    end

    def get_monthly_allocations(grouped_monthly_avail_dates, available_days, monthly_allocated_days, num_of_rooms)
      resorted_monthly_dates = sort_monthly_order(grouped_monthly_avail_dates.keys).map { |month| [month, monthly_allocated_days[month]] }.to_h
      valid_resorted_months = validate_available_days(resorted_monthly_dates, available_days, num_of_rooms)
      distribute_days_evenly(valid_resorted_months, available_days, num_of_rooms)
    end
  end
end
