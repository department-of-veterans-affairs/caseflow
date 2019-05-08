# frozen_string_literal: true

# Service to handle hearing time updates consistently between VACOLS and Caseflow
# using scheduled_time_string

class HearingTimeService
  class << self
    def build_legacy_params_with_time(hearing, update_params)
      # takes hearing update_legacy_params from controller and adds
      # vacols-formatted datetime
      return update_params if update_params[:scheduled_time_string].nil?

      scheduled_for = vacols_formatted_datetime(
        scheduled_for: update_params[:scheduled_for] || hearing.scheduled_for,
        scheduled_time_string: update_params[:scheduled_time_string]
      )

      remove_time_string_params(update_params).merge(scheduled_for: scheduled_for)
    end

    def build_params_with_time(_hearing, update_params)
      return update_params if update_params[:scheduled_time_string].nil?

      remove_time_string_params(update_params).merge(scheduled_time: update_params[:scheduled_time_string])
    end

    def vacols_formatted_datetime(scheduled_for:, scheduled_time_string:)
      hour, min = scheduled_time_string.split(":")

      time = scheduled_for.to_datetime.change(
        hour: hour.to_i,
        min: min.to_i
      )

      Time.utc(time.year, time.month, time.day, time.hour, time.min, time.sec)
    end

    def time_to_string(time)
      return time if time.is_a?(String)

      datetime = time.to_datetime
      "#{pad_time(datetime.hour)}:#{pad_time(datetime.min)}"
    end

    private

    def pad_time(time)
      "0#{time}".chars.last(2).join
    end

    def remove_time_string_params(params)
      params.reject { |param| param.to_sym == :scheduled_time_string }
    end
  end

  def initialize(hearing:)
    @hearing = hearing
  end

  def to_s
    return self.class.time_to_string(@hearing.scheduled_for) if @hearing.is_a?(LegacyHearing)

    self.class.time_to_string(@hearing.scheduled_time)
  end

  def to_datetime
    @hearing.scheduled_time if @hearing.is_a?(Hearing)

    time = @hearing.scheduled_for.to_datetime
    # format consistent with Hearing scheduled_time column
    Time.utc(2000, 1, 1, time.hour, time.min, time.sec)
  end

  def central_office_time
    hour, min = to_s.split(":")
    hearing_time = DateTime.current.change(
      hour: hour.to_i,
      min: min.to_i,
      offset: Time.now.in_time_zone(@hearing.regional_office_timezone).strftime("%z")
    )

    co_time = hearing_time.in_time_zone("America/New_York")

    self.class.time_to_string(co_time)
  end
end
