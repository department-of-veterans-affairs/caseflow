module DateHelper
  def get_unique_dates_between(start_date, end_date, num_of_dates, exclude_weekends = true)
    dates = Set.new

    return nil if (end_date - start_date) < num_of_dates

    while dates.size <= num_of_dates
      date = Faker::Date.between(start_date, end_date)
      dates.add(date) unless exclude_weekends && (date.saturday? || date.sunday?)
    end

    dates.to_a
  end
end