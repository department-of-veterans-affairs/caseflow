# frozen_string_literal: true

module HearingTimeConcern
  extend ActiveSupport::Concern

  delegate :central_office_time_string, :scheduled_time_string,
           to: :time

  #  A façade for a hearing's memoized time service instance - either {HearingTimeService} or {HearingDatetimeService},
  # depending on the hearing's attributes.
  #
  # @return [HearingTimeService] if {Hearing#use_hearing_datetime?} or {LegacyHearing#use_hearing_datetime?} is false
  # @return [HearingDatetimeService] if {Hearing#use_hearing_datetime?} or {LegacyHearing#use_hearing_datetime?} is true
  def time
    @time ||= if use_hearing_datetime?
                HearingDatetimeService.new(hearing: self)
              else
                HearingTimeService.new(hearing: self)
              end
  end

  # The hearing's local time cast into the POA's timezone
  #
  # @return [Time]
  #   The hearing time in the representative recipient's timezone, if available.
  # @return [Time]
  #   The hearing time in the virtual_hearings' representative_tz, if representative's timezone missing on the hearing.
  # @return [Time]
  #   Fall back to the hearing's default local time if neither are available.
  def poa_time
    representative_tz_from_recipient = representative_recipient&.timezone
    return normalized_time(representative_tz_from_recipient) if representative_tz_from_recipient.present?

    return normalized_time(virtual_hearing[:representative_tz]) if virtual_hearing.present?

    normalized_time(nil)
  end

  # The hearing's local time cast into the appellant's timezone
  #
  # @return [Time]
  #   The hearing time in appellant recipient's timezone, if available.
  # @return [Time]
  #   The hearing time in the virtual_hearing's appellant_tz, if appellant's timezone is not available from the hearing.
  # @return [Time]
  #   Fall back to the hearing's default local time if neither are available.
  def appellant_time
    appellant_tz_from_recipient = appellant_recipient&.timezone
    return normalized_time(appellant_tz_from_recipient) if appellant_tz_from_recipient.present?

    return normalized_time(virtual_hearing[:appellant_tz]) if virtual_hearing.present?

    normalized_time(nil)
  end

  private

  # @param timezone [String] A timezone in a format readable by Rails ActiveSupport::TimeZone.
  #
  # @return [Time] The hearing's local time cast into the supplied timezone.
  # @return [Time] Fall back to the hearing's default local time if the supplied timezone is nil.
  def normalized_time(timezone)
    return time.local_time if timezone.nil?

    time.local_time.in_time_zone(timezone)
  end
end
