# frozen_string_literal: true

# TO-DO: confirm open-uri
require "open-uri"

class DownloadTranscriptionFileJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  retry_on(StandardError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.info("RETRY")
  end

  # TO-DO: confirm priority
  queue_with_priority :low_priority

  # TO-DO: confirm arguments
  def perform(temporary_link:, docket_number:, appeal: nil)
    Rails.logger.info("START JOB")
    ensure_current_user_is_set
    begin
      download_to_tmp_location(temporary_link)
      @transcription_file = create_transcription_file(docket_number: docket_number, appeal: appeal)
      Rails.logger.info("FINISH JOB")
    ensure
      Rails.logger.info("CLEAN UP")
      clean_up_tmp_location
    end
  end

  private

  def download_to_tmp_location(temporary_link)
    URI.open(temporary_link) do |download|
      parse_file_name(download)
      IO.copy_stream(download, tmp_location)
    end
  end

  def parse_file_name(download)
    @file_name = download.base_uri.to_s.split("/")[-1]
  end

  # TO-DO: figure out how to parse file_type
  def file_type
    @file_name.split(".")[-1]
  end

  def tmp_location
    File.join(Rails.root, "tmp", "transcription_files", @file_name)
  end

  def clean_up_tmp_location
    return unless @file_name && File.exist?(tmp_location)

    File.delete(tmp_location)
  end

  def create_transcription_file(docket_number:, appeal:)
    TranscriptionFile.create!(
      file_name: @file_name,
      file_type: file_type,
      docket_number: docket_number,
      appeal_id: appeal&.id,
      appeal_type: appeal&.class&.name,
      file_status: Constants.TRANSCRIPTION_FILE_STATUSES.retrieval.success,
      date_receipt_webex: Time.zone.today,
      created_by_id: RequestStore[:current_user]
    )
  end
end
