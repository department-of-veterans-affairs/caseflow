# frozen_string_literal: true

class HearingSchedule::DateValidators
  def initialize(date, start_date = nil, end_date = nil)
    @date = date
    @start_date = start_date
    @end_date = end_date
  end

  def date_correctly_formatted?
    @date.instance_of?(Date) || @date == "N/A"
  end

  def date_in_range?
    !@date.instance_of?(Date) || (@date >= @start_date && @date <= @end_date)
  end
end
