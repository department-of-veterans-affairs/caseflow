# frozen_string_literal: true

# This job will retrieve a list of webex hearing recording detail links
# and download the information from the links

class Hearings::FetchWebexRecordingsDetailsJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet
  include Hearings::SendTranscriptionIssuesEmail
  include WebexConcern

  queue_with_priority :low_priority
  application_attr :hearing_schedule
  attr_reader :recording_id, :host_email, :meeting_title

  # rubocop:disable Layout/LineLength
  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    recording_id = job.arguments&.first&.[](:recording_id)
    host_email = job.arguments&.first&.[](:host_email)
    meeting_title = job.arguments&.first&.[](:meeting_title)
    query = "?hostEmail=#{host_email}"
    error_details = {
      error: { type: "retrieval", explanation: "retrieve recording details from Webex" },
      provider: "webex",
      api_call:
        "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}recordings/#{recording_id}#{query}",
      response: { status: exception.code, message: exception.message }.to_json,
      recording_id: recording_id,
      host_email: host_email,
      meeting_title: meeting_title
    }
    job.log_error(exception)
    job.send_transcription_issues_email(error_details)
  end
  # rubocop:enable Layout/LineLength

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
    query = { "hostEmail": email }
    WebexService.new(recordings_config(query)).fetch_recording_details(id)
  end

  def create_file_name(topic, extension, meeting_title)
    counter = topic.split("-").last
    "#{meeting_title}-#{counter}.#{extension}"
  end

  def send_file(topic, extension, link, meeting_title)
    file_name = create_file_name(topic, extension, meeting_title)
    Hearings::DownloadTranscriptionFileJob.perform_later(download_link: link, file_name: file_name)
  end
end
