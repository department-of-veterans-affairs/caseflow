# frozen_string_literal: true

# TO-DO: confirm open-uri
require "open-uri"

class DownloadTranscriptionFileJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  # TO-DO: confirm priority
  queue_with_priority :low_priority

  class TranscriptionFileNameError < StandardError; end

  retry_on(OpenURI::HTTPError, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")

    # Raven.capture_exception(exception, extra: extra)
    # Send email to VA?
  end

  discard_on(TranscriptionFileNameError) do |job, exception|
    Rails.logger.warn("Discarding #{job.class.name} (#{job.job_id})failed with error: #{exception}")
  end

  VALID_FILE_TYPES = %w[mp4 vtt].freeze

  # Purpose: Downloads audio (mp4) or transcript (vtt) file from temporary download link provided by
  #          GetRecordingDetailsJob
  #
  # Params: download_link - string, URI for temporary download link
  #         file_name - string, to be parsed for appeal/hearing identifiers
  def perform(download_link:, file_name:)
    ensure_current_user_is_set
    @file_name = file_name
    @transcription_file = find_or_create_transcription_file

    begin
      download_to_tmp(download_link)
    ensure
      clean_up_tmp_location
    end
  end

  private

  attr_reader :file_name

  # Purpose: Downloads audio (mp4) or transcript (vtt) file from temporary download link provided by
  #          GetRecordingDetailsJob. Update file status of transcription file depending on download success/failure.
  #
  # Params: download_link - string, URI for temporary download link
  #         file_name - string, to be parsed for appeal/hearing identifiers
  #
  # Returns: nil if successful, OpenURI::HTTPError if failure
  def download_to_tmp(link)
    begin
      URI.open(link) do |download|
        IO.copy_stream(download, tmp_location)
      end
      update_file_status_after_download(status: :success, date: Time.zone.now)
    rescue OpenURI::HTTPError => error
      update_file_status_after_download(status: :failure)
      raise error
    end
  end

  # Purpose: Location of temporary file in tmp/transcription_files/<file_type> directory
  #
  # Returns: string, directory path
  def tmp_location
    File.join(Rails.root, "tmp", "transcription_files", file_type, file_name)
  end

  # Purpose: Removes temporary file (if it exists) from tmp folder after job success/fails
  #
  # Returns: integer value of 1 if file deleted, nil if file not found
  def clean_up_tmp_location
    return unless file_name && File.exist?(tmp_location)

    File.delete(tmp_location)
  end

  # Purpose: Either mp4 (audio) or vtt (transcript)
  #
  # Returns: string, file type
  def file_type
    file_name.split(".").last
  end

  # Purpose: Determines if file type parsed from file name is valid
  #
  # Returns: boolean
  def file_type_invalid?
    return unless VALID_FILE_TYPES.exclude?(file_type)

    fail TranscriptionFileNameError, "Invalid file type"
  end

  # Purpose: Appeal associated with the hearing for which the transcription was created
  #
  # Returns: Appeal object or nil
  def appeal
    @appeal ||= parse_appeal if appeal_attributes_present?
  end

  # Purpose: Determines if file name includes sufficient identifiers to parse appeal
  #
  # Returns: boolean
  def appeal_attributes_present?
    file_name.include?("Appeal")
  end

  # Purpose: Parses appeal details from identifiers present in file name
  #
  # Returns: Appeal object or error if appeal not able to be found
  def parse_appeal
    begin
      appeal_info = file_name.split(".").first
      appeal_id = appeal_info.split("_")[1]
      appeal_type = appeal_info.split("_")[2]
      appeal_type.constantize.find(appeal_id)
    rescue StandardError
      raise TranscriptionFileNameError, "File name missing sufficient appeal/hearing identifiers"
    end
  end

  # Purpose: Docket number associated with the hearing for which the transcription was created
  #
  # Returns: string or error
  def docket_number
    appeal&.docket_number || docket_number_from_hearing_day
  end

  # TO-DO: How to implement parsing docket number from hearing day?
  def docket_number_from_hearing_day
    fail NotImplementedError
  end

  # Purpose: If job previously failed and retry initiated, finds existing transcription file record. Otherewise, create
  #          new record.
  #
  # Returns: TranscriptionFile object
  def find_or_create_transcription_file
    TranscriptionFile.find_or_create_by(
      file_name: file_name,
      docket_number: docket_number,
      appeal_id: appeal&.id,
      appeal_type: appeal&.class&.name
    ) do |file|
      file.file_type = file_type unless file_type_invalid?
      file.created_by_id = RequestStore[:current_user]
    end
  end

  # Purpose: Update sthe @transcription_file with success or failure status after download complets. If download
  #          successful, update date_receipt_webex.
  #
  # Returns: TranscriptionFile object
  def update_file_status_after_download(status:, date: nil)
    @transcription_file.update!(
      file_status: Constants.TRANSCRIPTION_FILE_STATUSES.retrieval.send(status),
      date_receipt_webex: date
    )
  end
end
