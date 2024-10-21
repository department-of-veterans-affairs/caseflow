# frozen_string_literal: true

# This job retrieves details about a specific meeting room from Webex using their API.
class Hearings::FetchWebexRoomMeetingDetailsJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet
  include Hearings::SendTranscriptionIssuesEmail
  include WebexConcern

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  attr_reader :room_id, :meeting_title

  class NoMeetingIdError < StandardError; end

  discard_on(NoMeetingIdError) do |job, exception|
    job.log_error(exception)
  end

  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    room_id = job.arguments&.first&.[](:room_id)
    meeting_title = job.arguments&.first&.[](:meeting_title)
    error_details = {
      error: { type: "retrieval", explanation: "retrieve details of room from Webex" },
      provider: "webex",
      api_call:
        "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}rooms/#{room_id}/meetingInfo",
      response: { status: exception.code, message: exception.message }.to_json,
      room_id: room_id,
      meeting_title: meeting_title
    }
    job.log_error(exception)
    job.send_transcription_issues_email(error_details)
  end

  def perform(room_id:, meeting_title:)
    ensure_current_user_is_set
    room_meeting_details = fetch_room_details(room_id)
    fail NoMeetingIdError if room_meeting_details.meeting_id.nil?

    Hearings::FetchWebexRecordingsListJob.perform_later(
      meeting_id: room_meeting_details.meeting_id,
      meeting_title: meeting_title
    )
  end

  private

  # This constructs the headers and calls on the webex endpoint
  # to retreive the meeting details from the specified room using ID
  # Params: id - The unique ID of the webex room
  # Return: The response object created from the response from the API
  def fetch_room_details(id)
    WebexService.new(rooms_config).fetch_room_details(id)
  end
end
