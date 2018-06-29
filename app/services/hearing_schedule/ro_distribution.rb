module HearingSchedule::RoDistribution
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def montly_percentage_for_period(start_date, end_date)
      # FIX THIS! number of days is incorrect here
      (start_date..end_date).group_by { |d| [d.month, d.year] }.map do |group|
        [group[0], ((group.last.last - group.last.first).to_f / (group.last.first.end_of_month - group.last.first.beginning_of_month).to_f) * 100]
      end.to_h
    end

    def weight_by_percentages(monthly_percentages)
      percenrage_sum = monthly_percentages.map { |_k, v| v }.inject(:+)
      monthly_percentages.map { |date, num| [date, (num / percenrage_sum)] }.to_h
    end

    def shuffle_grouped_monthly_dates(grouped_monthly_dates)
      grouped_monthly_dates.map do |ro_key, dates|
        [ro_key, dates.shuffle.reduce({}) do |acc, date|
          acc[date] = []
          acc
        end]
      end.to_h
    end
  end
end
