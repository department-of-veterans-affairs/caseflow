module DateTimeHelper
  def post_ama_start_date
    ama_start_date + 100.days
  end

  def ama_start_date
    DecisionReview.ama_activation_date.in_time_zone
  end

  def pre_ramp_start_date
    Time.new(2016, 12, 8).in_time_zone
  end

  def ramp_start_date
    Time.new(2017, 11, 1).in_time_zone
  end

  def post_ramp_start_date
    Time.new(2017, 12, 8).in_time_zone
  end
end

class Date
  # rubocop:disable Naming/MethodName
  def mdY
    strftime("%m/%d/%Y")
  end
  # rubocop:enable Naming/MethodName

  # cheatsheet from https://apidock.com/ruby/DateTime/strftime
  #   Combination:
  #   %c - date and time (%a %b %e %T %Y)
  #   %D - Date (%m/%d/%y)
  #   %F - The ISO 8601 date format (%Y-%m-%d)
  #   %v - VMS date (%e-%b-%Y)
  #   %x - Same as %D
  #   %X - Same as %T
  #   %r - 12-hour time (%I:%M:%S %p)
  #   %R - 24-hour time (%H:%M)
  #   %T - 24-hour time (%H:%M:%S)
  #   %+ - date(1) (%a %b %e %H:%M:%S %Z %Y)
end
