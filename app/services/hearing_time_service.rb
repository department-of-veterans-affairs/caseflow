# frozen_string_literal: true

class HearingTimeService
  class << self
    def build_params_with_time(hearing, update_params)
      return update_params if update_params[:scheduled_for_time].nil?

      update_params.merge(
        time_params(
          hearing,
          scheduled_for: update_params[:scheduled_for],
          scheduled_for_time: update_params[:scheduled_for_time]
        )
      )
    end

    def vacols_formatted_datetime(scheduled_for:, scheduled_for_time:)
      hour, min = scheduled_for_time.split(":")

      hearing_datetime = scheduled_for.to_datetime.change(
        hour: hour.to_i,
        min: min.to_i
      )

      VacolsHelper.format_datetime_with_utc_timezone(hearing_datetime)
    end

    private

    def time_params(hearing, scheduled_for:, scheduled_for_time:)
      if hearing.is_a?(LegacyHearing)
        hour, min = scheduled_for_time.split(":")
        scheduled_for = vacols_formatted_datetime(
          scheduled_for: scheduled_for || hearing.scheduled_for,
          hour: hour,
          min: min
        )

        { scheduled_for: scheduled_for }
      else
        { scheduled_for_time: scheduled_for_time }
      end
    end
  end

  def initialize(hearing:)
    @hearing = hearing
  end

  def to_s
    if @hearing.is_a?(LegacyHearing)
      time_string_from_vacols_hearing_date
    else
      @hearing.scheduled_for_time || time_string_from_scheduled_time
    end
  end

  def date
    @hearing.scheduled_for.to_date
  end

  def central_office_time_string
    hour_min = to_s.split(":")
    hearing_time = DateTime.current.change(
      hour: hour_min[0],
      min: hour_min[1],
      offset: Time.now.in_time_zone(@hearing.regional_office_timezone).strftime("%z")
    )

    co_time = hearing_time.in_time_zone("America/New_York")

    "#{co_time.hour}:#{co_time.min}"
  end

  private

  def time_string_from_scheduled_time
    # we are deprecating the use of the scheduled_time datetime column in
    # favor of the scheduled_for_time string column
    "#{@hearing.scheduled_time.hour}:#{@hearing.scheduled_time.min}"
  end

  def time_string_from_vacols_hearing_date
    "#{@hearing.scheduled_for.hour}:#{@hearing.scheduled_for.min}"
  end
end
