# frozen_string_literal: true

# TO-DO: confirm open-uri
require "open-uri"

class DownloadTranscriptionFileJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  # TO-DO: confirm priority
  queue_with_priority :low_priority

  class TranscriptionFileNameError < StandardError; end
  class HearingAssociationError < StandardError; end

  retry_on(OpenURI::HTTPError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")

    file_name = job.arguments.first[:file_name]
    hearing_id = file_name.split("_")[1]
    extra = {
      application: job.class.app_name.to_s,
      hearing_id: hearing_id,
      file_name: file_name,
      job_id: job.job_id
    }
    Raven.capture_exception(exception, extra: extra)

    # TO-DO
    # send_error_email_to_va_ops(exception)
  end

  discard_on(TranscriptionFileNameError) do |job, exception|
    Rails.logger.warn("Discarding #{job.class.name} (#{job.job_id}) failed with error: #{exception}")

    # TO-DO
    # send_error_email_to_va_ops(exception)
  end

  VALID_FILE_TYPES = %w[mp4 vtt].freeze

  S3_BUCKET_NAMES = {
    mp4: "transcript_audio",
    vtt: "transcript_raw"
  }.freeze

  # Purpose: Downloads audio (mp4) or transcript (vtt) file from temporary download link provided by
  #          GetRecordingDetailsJob
  #
  # Params: download_link - string, URI for temporary download link
  #         file_name - string, to be parsed for appeal/hearing identifiers
  def perform(download_link:, file_name:)
    ensure_current_user_is_set
    @file_name = file_name
    ensure_hearing_held
    @transcription_file = find_or_create_transcription_file

    begin
      download_file_to_tmp(download_link)
      upload_file_to_s3
      # queue_transform_job
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
  # Returns: Updated @transcription_file
  def download_file_to_tmp(link)
    begin
      URI.open(link) do |download|
        IO.copy_stream(download, tmp_location)
      end
      update_file_after_download(status: :success, date: Time.zone.now)
    rescue OpenURI::HTTPError => error
      update_file_after_download(status: :failure)
      raise error
    end
  end

  # Purpose: Location of temporary file in tmp/transcription_files/<file_type> directory
  #
  # Returns: string, directory path
  def tmp_location
    File.join(Rails.root, "tmp", "transcription_files", file_type, file_name)
  end

  # Purpose: Downloads audio (mp4) or transcript (vtt) file from tmp directory to s3 location
  #
  # Returns: Updated @transcription_file
  def upload_file_to_s3
    begin
      S3Service.store_file(s3_bucket, tmp_location, :filepath)
      update_file_after_upload(status: :success, aws_link: s3_file_location, date: Time.zone.now)
    rescue StandardError => error
      update_file_after_upload(status: :failure)
      raise error
    end
  end

  # Purpose: Bucket name in s3 depending on if file type mp4 or vtt
  #
  # Returns: string, bucket name
  def s3_bucket
    S3_BUCKET_NAMES[file_type.to_sym]
  end

  # Purpose: Location of successfully uploaded file in s3
  #
  # Returns: string, s3 filepath
  def s3_file_location
    s3_bucket + "/" + file_name
  end

  # Purpose: Location of successfully uploaded file in s3
  #
  # Returns: string, s3 filepath
  def queue_transform_job
    case file_type
    when "mp4"
      TransformMp4ToMp3Job.perform_later(s3_file_location)
    when "vtt"
      TransformVttToRtfJob.perform_later(s3_file_location)
    end
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
    return false if VALID_FILE_TYPES.include?(file_type)

    fail TranscriptionFileNameError, "Invalid file type"
  end

  # Purpose: Hearing for which the transcription was created
  #
  # Returns: Hearing object
  def hearing
    @hearing ||= parse_hearing
  end

  # Purpose: Parses hearing details from identifiers present in file name
  #
  # Returns: Hearing object or error if hearing not able to be found
  def parse_hearing
    begin
      hearing_details = file_name.split(".").first
      hearing_id = hearing_details.split("_")[1]
      hearing_type = hearing_details.split("_")[2]
      hearing_type.constantize.find(hearing_id)
    rescue StandardError
      raise TranscriptionFileNameError, "File name missing sufficient hearing identifiers"
    end
  end

  # Purpose: If disposition of hearing is not marked as held, sends email to VA Operations Team and continues with
  #          download
  def ensure_hearing_held
    return if hearing.held?

    # TO-DO
    # send_error_email_to_va_ops(HearingAssociationError.new("Hearing disposition not set to held"))
  end

  # Purpose: Appeal associated with the hearing for which the transcription was created
  #
  # Returns: Appeal object
  def appeal
    @appeal ||= hearing.appeal
  end

  # Purpose: Docket number associated with the hearing for which the transcription was created
  #
  # Returns: string or error
  def docket_number
    appeal&.docket_number
  end

  # Purpose: Finds existing transcription file record if job previously failed and retry initiated. Otherewise, creates
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

  # Purpose: Updates the @transcription_file with success or failure status after download completes. If download
  #          successful, updates date_receipt_webex.
  #
  # Returns: TranscriptionFile object
  def update_file_after_download(status:, date: nil)
    @transcription_file.update!(
      file_status: Constants.TRANSCRIPTION_FILE_STATUSES.retrieval.send(status),
      date_receipt_webex: date
    )
  end

  # Purpose: Updates the @transcription_file with success or failure status after upload to s3 completes. If upload
  #          successful, updates date_upload_aws and aws_link.
  #
  # Returns: TranscriptionFile object
  def update_file_after_upload(status:, aws_link: nil, date: nil)
    @transcription_file.update!(
      file_status: Constants.TRANSCRIPTION_FILE_STATUSES.upload.send(status),
      aws_link: aws_link,
      date_upload_aws: date
    )
  end
end
