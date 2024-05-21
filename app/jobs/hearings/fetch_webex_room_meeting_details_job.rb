# frozen_string_literal: true

# This job retrieves details about a specific meeting room from Webex using their API.
class Hearings::FetchWebexRoomMeetingDetailsJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet
  include Hearings::SendTranscriptionIssuesEmail

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  attr_reader :room_id, :meeting_title

  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    error_details = {
      error: { type: "retrieval", explanation: "retrieve details of room from Webex" },
      provider: "webex",
      api_call: "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}",
      response: { status: exception.code, message: exception.message }.to_json,
      times: nil,
      docket_number: nil
    }
    job.log_error(exception)
    job.send_transcription_issues_email(error_details)
  end

  def perform(room_id:, meeting_title:)
    ensure_current_user_is_set
    fetch_room_details
    # params will be room_id, meeting_title later
    Hearings::FetchWebexRecordingsListJob.perform_now
  end

  private

  # This constructs the headers and calls on the webex endpoint for getting details of a room
  # Params: room_id - The unique ID of the webex room
  # Return: The response object created from the response from the API
  def fetch_room_details
    WebexService.new(
      host: ENV["WEBEX_HOST_MAIN"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: ENV["WEBEX_MASTER_BOT_TOKEN"],
      domain: ENV["WEBEX_DOMAIN_MAIN"],
      api_endpoint: ENV["WEBEX_API_MAIN"],
      query: nil
    ).fetch_room_details(room_id)
  end
end
