# frozen_string_literal: true

# This job will get a list of webex recordings made for hearings that have happened
# Within 24 hours from the time it is run as well as the details for those recordings

class Hearings::GetWebexRecordingsListJob

  queue_with_priority :low_priority
  application_attr :queue

  class IncompleteError < StandardError; end

  def perform
    RequestStore[:current_user] = User.system_user

    find_ids(get_recordings)


  end

  private

  def get_recordings
    from = Time.parse("#{Time.zone.today.strftime('%Y-%m-%e')}T21:30:00-05:00")
    to = Time.parse("#{1.day.ago.strftime('%Y-%m-%e')}T21:30:00-05:00")

    # Breaking the service into two modules would probably make this so much simpler
    WebexService.new(
      host: ENV["WEBEX_HOST_MAIN"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: ENV["WEBEX_BOTTOKEN"],
      domain: ENV["WEBEX_DOMAIN_MAIN"],
      api_endpoint: ENV["WEBEX_API_MAIN"],
      from: from,
      to: to
    ).get_recordings_list
  end

  def find_ids(recordings)
    recording_ids = recordings.data["items"]
  end
end
