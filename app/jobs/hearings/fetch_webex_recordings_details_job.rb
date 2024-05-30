# frozen_string_literal: true

# This job will retrieve a list of webex hearing recording detail links
# and download the information from the links

class Hearings::FetchWebexRecordingsDetailsJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet
  include Hearings::SendTranscriptionIssuesEmail

  queue_with_priority :low_priority
  application_attr :hearing_schedule
  attr_reader :recording_id, :host_email, :meeting_title

  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    recording_id = job.arguments&.first&.[](:recording_id)
    error_details = {
      error: { type: "retrieval", explanation: "retrieve recording details from Webex" },
      provider: "webex",
      recording_id: recording_id,
      api_call: "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}/#{recording_id}",
      response: { status: exception.code, message: exception.message }.to_json,
      docket_number: nil
    }
    job.log_error(exception)
    job.send_transcription_issues_email(error_details)
  end

  def perform(recording_id:, host_email:, meeting_title:)
    ensure_current_user_is_set
    data = fetch_recording_details(recording_id, host_email)
    topic = data.topic

    mp4_link = data.mp4_link
    send_file(topic, "mp4", mp4_link, meeting_title)

    vtt_link = data.vtt_link
    send_file(topic, "vtt", vtt_link, meeting_title)

    mp3_link = data.mp3_link
    send_file(topic, "mp3", mp3_link, meeting_title)
  end

  def log_error(error)
    extra = {
      application: self.class.name,
      job_id: job_id
    }
    super(error, extra: extra)
  end

  private

  def fetch_recording_details(id, email)
    query = { "host_email": email }
    WebexService.new(
      host: ENV["WEBEX_HOST_MAIN"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: WebexService.access_token,
      domain: ENV["WEBEX_DOMAIN_MAIN"],
      api_endpoint: ENV["WEBEX_API_MAIN"],
      query: query
    ).fetch_recording_details(id)
  end

  def create_file_name(topic, extension, meeting_title)
    title = meeting_title.scan(/\d*-*\d+_\d+_[A-Za-z]*Hearing+(?=-)/).first
    counter = topic.split("-").last
    "#{title}-#{counter}.#{extension}"
  end

  def send_file(topic, extension, link, meeting_title)
    file_name = create_file_name(topic, extension, meeting_title)
    Hearings::DownloadTranscriptionFileJob.perform_later(download_link: link, file_name: file_name)
  end
end
