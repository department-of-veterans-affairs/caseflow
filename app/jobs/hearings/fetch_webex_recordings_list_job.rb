# frozen_string_literal: true

# This job will retrieve a list of webex hearing recordings and details every hour

class Hearings::FetchWebexRecordingsListJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet
  include Hearings::SendTranscriptionIssuesEmail

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  attr_reader :meeting_id, :meeting_title

  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    max = 100
    id = job.arguments&.first&.[](:meeting_id)
    query = "?max=#{max}?meeting_id=#{id}"
    error_details = {
      error: { type: "retrieval", explanation: "retrieve a list of recordings from Webex" },
      provider: "webex",
      api_call: "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}#{query}",
      response: { status: exception.code, message: exception.message }.to_json,
      times: nil,
      docket_number: nil
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
    query = { "max": max, "meeting_id": meeting_id }
    WebexService.new(
      host: ENV["WEBEX_HOST_MAIN"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: CredStash.get("webex_#{Rails.deploy_env}_access_token"),
      domain: ENV["WEBEX_DOMAIN_MAIN"],
      api_endpoint: ENV["WEBEX_API_MAIN"],
      query: query
    ).fetch_recordings_list
  end
end
