# frozen_string_literal: true

class FetchWebexRoomMeetingDetailsJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  def perform(room_id, meeting_title)
    ensure_current_user_is_set
    fetch_webex_room_meeting_details(room_id)
    FetchWebexRecordingListJob.perform_now(room_id, meeting_title)
  end

  def fetch_webex_room_meeting_details(room_id)
    WebexService.new(
      host: ENV["WEBEX_HOST_MAIN"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: CredStash.get("webex_#{Rails.deploy_env}_access_token"),
      domain: ENV["WEBEX_DOMAIN_MAIN"],
      api_endpoint: ENV["WEBEX_API_MAIN"],
      query: nil
    ).fetch_webex_room_meeting_details(room_id)
  end
end
