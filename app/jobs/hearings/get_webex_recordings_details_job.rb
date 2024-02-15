# frozen_string_literal: true

# This job will retrieve a list of webex hearing recording detail links
# and download the information from the links

class Hearings::GetWebexRecordingsDetailsJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :hearing_schedule
  attr_reader :id

  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    # TO IMPLEMENT: SEND EMAIL TO VA OPS TEAM
    job.log_error(exception)
  end

  def perform(id:)
    ensure_current_user_is_set
    topic = get_recording_details(id).topic

    # How can I dry this up
    mp4_link = get_recording_details(id).mp4_link
    mp4_file_name = create_file_name(topic, "mp4")
    Hearings::DownloadTranscriptionFileJob.new(mp4_link, mp4_file_name)

    vtt_link = get_recording_details(id).vtt_link
    vtt_file_name = create_file_name(topic, "vtt")
    Hearings::DownloadTranscriptionFileJob.new(vtt_link, vtt_file_name)

    mp3_link = get_recording_details(id).mp3_link
    mp3_file_name = create_file_name(topic, "mp3")
    Hearings::DownloadTranscriptionFileJob.new(mp3_link, mp3_file_name)
  end

  def log_error(error)
    Rails.logger.error("Retrying #{self.class.name} because failed with error: #{error}")
    extra = {
      application: self.class.name,
      job_id: job_id
    }
    Raven.capture_exception(error, extra: extra)
  end

  private

  def get_recording_details(id)
    query = { "id": id }

    WebexService.new(
      host: ENV["WEBEX_HOST_MAIN"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: ENV["WEBEX_BOTTOKEN"],
      domain: ENV["WEBEX_DOMAIN_MAIN"],
      api_endpoint: ENV["WEBEX_API_MAIN"],
      query: query
    ).get_recording_details
  end

  def create_file_name(topic, extension)
    subject = topic.scan(/\d*-\d*_\d*_[A-Za-z]+?(?=-)/).first
    counter = topic.split("-").last
    "#{subject}-#{counter}.#{extension}"
  end
end
