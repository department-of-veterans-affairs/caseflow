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
    data = get_recording_details(id)
    topic = data.topic

    mp4_link = data.mp4_link
    send_file(topic, "mp4", mp4_link)

    vtt_link = data.vtt_link
    send_file(topic, "vtt", vtt_link)

    mp3_link = data.mp3_link
    send_file(topic, "mp3", mp3_link)
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
    type = topic.scan(/[A-Za-z]+?(?=-)/).first
    subject = if type == "Hearing"
                topic.scan(/\d*-\d*_\d*_[A-Za-z]+?(?=-)/).first
              else
                topic.scan(/\d*_\d*_[A-Za-z]+?(?=-)/).first
              end
    counter = topic.split("-").last
    "#{subject}-#{counter}.#{extension}"
  end

  def send_file(topic, extension, link)
    file_name = create_file_name(topic, extension)
    Hearings::DownloadTranscriptionFileJob.new.perform(download_link: link, file_name: file_name)
  end
end
