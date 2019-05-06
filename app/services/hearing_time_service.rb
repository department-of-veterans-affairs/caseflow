# frozen_string_literal: true

class HearingTimeService
  attr_accessor :hearing

  def self.handle_time_params(hearing_to_update, hearing_params:)
    # takes :hour/:minute params from controller and converts them to either vacols or caseflow
    # update params
    hour = hearing_params.delete(:hour)
    min = hearing_params.delete(:min)

    return hearing_params if hour.nil? || min.nil?

    generate_update_params(hearing_to_update, hearing_params)
  end

  def self.generate_update_params(hearing, hearing_params)
    hearing_params.tap do |params|
      if hearing.is_a?(LegacyHearing)
        params[:scheduled_for] = hearing.time.to_vacols_format(
          scheduled_for: hearing_params[:scheduled_for], hour: hour, min: min
        )
      else
        params[:scheduled_for_time] = "#{hour}:#{min}"
      end
    end
  end

  def initialize(hearing:)
    @hearing = hearing
  end

  def to_s
    if hearing.is_a?(LegacyHearing)
      time_string_from_vacols_hearing_date
    else
      hearing.scheduled_for_time || time_string_from_scheduled_time
    end
  end

  def to_vacols_format(scheduled_for: nil, hour:, min:)
    hearing_datetime = (scheduled_for || hearing.scheduled_for).to_datetime.change(
      hour: hour,
      min: min
    )

    VacolsHelper.format_datetime_with_utc_timezone(hearing_datetime)
  end

  def date
    hearing.scheduled_for.to_date
  end

  def central_office_time_string
    hour_min = to_s.split(":")
    hearing_time = DateTime.current.change(
      hour: hour_min[0],
      min: hour_min[1],
      offset: Time.now.in_time_zone(hearing.regional_office_timezone).strftime("%z")
    )

    co_time = hearing_time.in_time_zone("America/New_York")

    "#{co_time.hour}:#{co_time.min}"
  end

  def time_string_from_scheduled_time
    "#{hearing.scheduled_time.hour}:#{hearing.scheduled_time.min}"
  end

  def time_string_from_vacols_hearing_date
    "#{hearing.scheduled_for.hour}:#{hearing.scheduled_for.min}"
  end
end
