module DateTimeHelper
  def post_ama_start_date
    ama_start_date + 30.days
  end

  def ama_start_date
    Time.new(2019, 2, 14).in_time_zone
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
