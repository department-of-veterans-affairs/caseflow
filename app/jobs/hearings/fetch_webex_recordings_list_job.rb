# frozen_string_literal: true

# This job will retrieve a list of webex hearing recordings and details every hour

class Hearings::FetchWebexRecordingsListJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet
  include Hearings::SendTranscriptionIssuesEmail
  include WebexConcern

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  attr_reader :meeting_id, :meeting_title

  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    max = 100
    id = job.arguments&.first&.[](:meeting_id)
    meeting_title = job.arguments&.first&.[](:meeting_title)
    query = "?max=#{max}&meetingId=#{id}"
    error_details = {
      error: { type: "retrieval", explanation: "retrieve a list of recordings from Webex" },
      provider: "webex",
      api_call:
        "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}admin/recordings/#{query}",
      response: { status: exception.code, message: exception.message }.to_json,
      meeting_id: id,
      meeting_title: meeting_title
    }
    job.log_error(exception)
    job.send_transcription_issues_email(error_details)
  end

  def perform(meeting_id:, meeting_title:)
    ensure_current_user_is_set
    fetch_recordings_list(meeting_id).recordings.each do |recording|
      Hearings::FetchWebexRecordingsDetailsJob.perform_later(
        recording_id: recording.id, host_email: recording.host_email, meeting_title: meeting_title
      )
    end
  end

  def log_error(error)
    super(error, extra: { application: self.class.name, job_id: job_id })
  end

  private

  def fetch_recordings_list(id)
    max = 100
    meeting_id = id
    query = { "max": max, "meetingId": meeting_id }
    WebexService.new(recordings_config(query)).fetch_recordings_list
  end
end
