# frozen_string_literal: true

module FakeDateHelper
  # rubocop:disable Metrics/CyclomaticComplexity
  def get_unique_dates_between(start_date, end_date, num_of_dates,
                               exclude_weekends = true)
    dates = Set.new

    return nil if (end_date - start_date) < num_of_dates

    holidays = Holidays.between(start_date, end_date, :federal_reserve)

    while dates.size < num_of_dates
      date = Faker::Date.between(from: start_date, to: end_date)
      dates.add(date) unless (exclude_weekends && (date.saturday? || date.sunday?)) ||
                             holidays.find { |holiday| holiday[:date] == date }.present?
    end

    dates.to_a
  end

  def get_dates_between(start_date, end_date, num_of_dates,
                        exclude_weekends = true, max_same_date = 4)
    dates = []
    holidays = Holidays.between(start_date, end_date, :federal_reserve)

    while dates.size < num_of_dates
      date = Faker::Date.between(from: start_date, to: end_date)
      dates.push(date) unless (exclude_weekends && (date.saturday? || date.sunday?)) ||
                              holidays.find { |holiday| holiday[:date] == date }.present? ||
                              dates.count { |v| v == date } > max_same_date
    end

    dates.to_a
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def get_unique_dates_for_ro_between(ro_name, schedule_period, num_of_dates)
    get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, num_of_dates).map do |date|
      create(:ro_non_availability, date: date, schedule_period_id: schedule_period.id, object_identifier: ro_name)
    end
  end

  def get_every_nth_date_between(start_date, end_date, days_to_skip = 2, exclude_weekends = true)
    dates = []
    holidays = Holidays.between(start_date, end_date, :federal_reserve)
    date = start_date

    while date < end_date
      while (exclude_weekends && (date.saturday? || date.sunday?)) ||
            holidays.find { |holiday| holiday[:date] == date }.present?
        date += 1
      end

      dates.push(date)

      date += days_to_skip
    end

    dates
  end
end
