# frozen_string_literal: true

module HearingTimeConcern
  extend ActiveSupport::Concern

  delegate :central_office_time_string, :scheduled_time_string,
           to: :time

  def time
    @time ||= if is_a?(LegacyHearing) && scheduled_in_timezone || try(:scheduled_datetime)
                HearingDatetimeService.new(hearing: self)
              else
                HearingTimeService.new(hearing: self)
              end
  end

  # hearing time in poa timezone
  def poa_time
    # Check if there's a recipient, and if it has a timezone, it it does use that to set tz
    representative_tz_from_recipient = representative_recipient&.timezone
    return normalized_time(representative_tz_from_recipient) if representative_tz_from_recipient.present?
    # If there's a virtual hearing, use that tz even if it's empty
    return normalized_time(virtual_hearing[:representative_tz]) if virtual_hearing.present?

    # No recipient and no virtual hearing? Use the normalized_time fallback
    normalized_time(nil)
  end

  # hearing time in appellant timezone
  def appellant_time
    # Check if there's a recipient, and if it has a timezone, it it does use that to set tz
    appellant_tz_from_recipient = appellant_recipient&.timezone
    return normalized_time(appellant_tz_from_recipient) if appellant_tz_from_recipient.present?
    # If there's a virtual hearing, use that tz even if it's empty
    return normalized_time(virtual_hearing[:appellant_tz]) if hearing.virtual_hearing.present?

    # No recipient and no virtual hearing? Use the normalized_time fallback
    normalized_time(nil)
  end

  def normalized_time(timezone)
    return time.local_time if timezone.nil?

    # throws an error here if timezone is invalid
    time.local_time.in_time_zone(timezone)
  end
end
