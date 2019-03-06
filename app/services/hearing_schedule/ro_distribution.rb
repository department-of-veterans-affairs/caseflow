# frozen_string_literal: true

module HearingSchedule::RoDistribution
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    # Assigns a percentage for each month based on the number of days selected in the schedule period
    #
    # For example:
    # (2018-Jan-01, 2018-Jun-30)
    # returns -> {[1, 2018]=>100.0, [2, 2018]=>100.0, [3, 2018]=>100.0,
    #             [4, 2018]=>100.0, [5, 2018]=>100.0, [6, 2018]=>100.0}
    #
    # (2018-Jan-15, 2018-Jun-30)
    # returns -> {[1, 2018]=>53.333333333333336, [2, 2018]=>100.0, [3, 2018]=>100.0,
    #             [4, 2018]=>100.0, [5, 2018]=>100.0, [6, 2018]=>100.0}
    #
    def montly_percentage_for_period(start_date, end_date)
      (start_date..end_date).group_by { |d| [d.month, d.year] }.map do |group|
        number_of_days_in_month = (group.last.first.end_of_month - group.last.first.beginning_of_month).to_f
        [group[0], ((group.last.last - group.last.first).to_f / number_of_days_in_month) * 100]
      end.to_h
    end

    # Evently distributes weights to every month in the array based on the percentage of
    # days allocated to each month.
    #
    # For example:
    # (2018-Jan-01, 2018-Jun-30)
    # Monthly percentages:
    # [4, 2018] => 100.0, [5, 2018] => 100.0, [6, 2018] => 100.0,
    #   [7, 2018] => 100.0, [8, 2018] => 100.0
    # returns:
    # [4, 2018] => 0.2, [5, 2018] => 0.2, [6, 2018] => 0.2,
    #   [7, 2018] => 0.2, [8, 2018] => 0.2
    #
    def weight_by_percentages(monthly_percentages)
      percentage_sum = monthly_percentages.map { |_k, v| v }.inject(:+)
      monthly_percentages.map { |date, num| [date, (num / percentage_sum)] }.to_h
    end

    # shuffles the dates of each month in random order and assigns an empty array for each date
    # {[1, 2018]=> {Thu, 04 Jan 2018=>[], Tue, 02 Jan 2018=>[]}}
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
