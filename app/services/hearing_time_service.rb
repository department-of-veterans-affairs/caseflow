# frozen_string_literal: true

class HearingTimeService
  class << self
    def build_params_with_time(hearing, update_params)
      if hearing.is_a?(LegacyHearing) && update_params[:scheduled_for_time].present?
        scheduled_for = vacols_formatted_datetime(
          scheduled_for: update_params[:scheduled_for] || hearing.scheduled_for,
          scheduled_for_time: update_params[:scheduled_for_time]
        )

        remove_non_vacols_params(update_params).merge(scheduled_for: scheduled_for)
      else
        update_params
      end
    end

    def vacols_formatted_datetime(scheduled_for:, scheduled_for_time:)
      hour, min = scheduled_for_time.split(":")

      hearing_datetime = scheduled_for.to_datetime.change(
        hour: hour.to_i,
        min: min.to_i
      )

      VacolsHelper.format_datetime_with_utc_timezone(hearing_datetime)
    end

    def remove_non_vacols_params(params)
      params.reject { |param| param.to_sym == :scheduled_for_time }
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
    hour, min = to_s.split(":")
    hearing_time = DateTime.current.change(
      hour: hour.to_i,
      min: min.to_i,
      offset: Time.now.in_time_zone(@hearing.regional_office_timezone).strftime("%z")
    )

    co_time = hearing_time.in_time_zone("America/New_York")

    "#{pad_time(co_time.hour)}:#{pad_time(co_time.min)}"
  end

  private

  def time_string_from_scheduled_time
    # we are deprecating the use of the scheduled_time datetime column in
    # favor of the scheduled_for_time string column
    "#{pad_time(@hearing.scheduled_time.hour)}:#{pad_time(@hearing.scheduled_time.min)}"
  end

  def time_string_from_vacols_hearing_date
    "#{pad_time(@hearing.scheduled_for.hour)}:#{pad_time(@hearing.scheduled_for.min)}"
  end

  def pad_time(time)
    "0#{time}".chars.last(2).join
  end
end
