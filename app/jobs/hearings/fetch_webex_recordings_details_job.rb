# frozen_string_literal: true

# This job will retrieve a list of webex hearing recording detail links
# and download the information from the links

class Hearings::FetchWebexRecordingsDetailsJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :hearing_schedule
  attr_reader :id

  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    recording_id = job.arguments&.first&.[](:id)
    error_details = {
      error: { type: "retrieval", explanation: "retrieve recording details from Webex" },
      provider: "webex",
      recording_id: recording_id,
      api_call: "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}/#{recording_id}",
      response: { status: exception.code, message: exception.message }.to_json,
      docket_number: nil
    }
    TranscriptionFileIssuesMailer.issue_notification(error_details)
    job.log_error(exception)
  end

  def perform(id:, file_name:)
    ensure_current_user_is_set
    @file_name ||= file_name
    data = fetch_recording_details(id)
    topic = data.topic

    mp4_link = data.mp4_link
    send_file(topic, "mp4", mp4_link)

    vtt_link = data.vtt_link
    send_file(topic, "vtt", vtt_link)

    mp3_link = data.mp3_link
    send_file(topic, "mp3", mp3_link)
  end

  def log_error(error)
    extra = {
      application: self.class.name,
      job_id: job_id
    }
    super(error, extra: extra)
  end

  private

  def fetch_recording_details(id)
    config = {
      host: ENV["WEBEX_HOST_MAIN"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: ENV["WEBEX_BOTTOKEN"],
      domain: ENV["WEBEX_DOMAIN_MAIN"],
      api_endpoint: ENV["WEBEX_API_MAIN"],
      query: { "id": id }
    }

    WebexService.new(config: config).fetch_recording_details
  end

  def create_file_name(topic, extension)
    subject = topic.split("-").second.lstrip
    counter = topic.split("-").last
    "#{subject}-#{counter}.#{extension}"
  end

  def send_file(topic, extension, link)
    file_name = create_file_name(topic, extension)
    Hearings::DownloadTranscriptionFileJob.perform_later(download_link: link, file_name: file_name)
  end
end
