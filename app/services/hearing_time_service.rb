# frozen_string_literal: true

# Service to handle hearing time updates consistently between VACOLS and Caseflow
# using scheduled_time_string parameter.
# scheduled_time_string is always local time

class HearingTimeService
  class << self
    def build_legacy_params_with_time(hearing, update_params)
      # takes hearing update_legacy_params from controller and adds
      # vacols-formatted scheduled_for
      return update_params if update_params[:scheduled_time_string].nil?

      scheduled_for = legacy_formatted_scheduled_for(
        scheduled_for: update_params[:scheduled_for] || hearing.scheduled_for,
        scheduled_time_string: update_params[:scheduled_time_string]
      )

      remove_time_string_params(update_params).merge(scheduled_for: scheduled_for)
    end

    def build_params_with_time(_hearing, update_params)
      return update_params if update_params[:scheduled_time_string].nil?

      remove_time_string_params(update_params).merge(scheduled_time: update_params[:scheduled_time_string])
    end

    def legacy_formatted_scheduled_for(scheduled_for:, scheduled_time_string:)
      hour, min = scheduled_time_string.split(":")
      time = scheduled_for.to_datetime
      Time.use_zone("America/New_York") do
        Time.zone.now.change(
          year: time.year, month: time.month, day: time.day, hour: hour.to_i, min: min.to_i
        )
      end
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

  def scheduled_time_string
    self.class.time_to_string(local_time)
  end

  def central_office_time_string
    self.class.time_to_string(central_office_time)
  end

  def local_time
    # returns the date and time a hearing is scheduled for in the regional
    # office's time zone

    # for AMA hearings, return the hearing object's scheduled_for
    return @hearing.scheduled_for if @hearing.is_a?(Hearing)

    # for legacy hearings, convert to the regional office's time zone

    # if the hearing's regional_office_timezone is nil, assume this is a
    # central office hearing (eastern time)
    regional_office_timezone = @hearing.regional_office_timezone || "America/New_York"

    # scheduled_for returns hearing time in ET, convert back to local time
    @hearing.scheduled_for.in_time_zone(regional_office_timezone)
  end

  def central_office_time
    local_time.in_time_zone("America/New_York")
  end

  def scheduled_time
    return @hearing.scheduled_time if @hearing.is_a?(Hearing)

    Time.zone.local_to_utc(local_time).change(year: 2000, month: 1, day: 1)
  end
end
