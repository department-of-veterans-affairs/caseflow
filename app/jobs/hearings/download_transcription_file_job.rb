# frozen_string_literal: true

require "open-uri"

# Downloads transcription file from Webex using temporary download link and uploads to S3
# - Download link passed to this job from GetRecordingDetailsJob
# - File type either audio (mp3), video (mp4), or vtt (transcript)

class DownloadTranscriptionFileJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority

  attr_reader :file_name

  class FileNameError < StandardError; end
  class FileDownloadError < StandardError; end
  class FileUploadError < StandardError; end
  class HearingAssociationError < StandardError; end

  VALID_FILE_TYPES = %w[mp3 mp4 vtt].freeze

  S3_SUB_BUCKET = "vaec-appeals-caseflow"

  S3_SUB_FOLDERS = {
    mp3: "transcript_audio",
    mp4: "transcript_audio",
    vtt: "transcript_raw"
  }.freeze

  retry_on(FileDownloadError, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")
    extra = {
      application: job.class.app_name.to_s,
      hearing_id: job.hearing.id,
      file_name: job.file_name,
      job_id: job.job_id
    }
    Raven.capture_exception(exception, extra: extra)
    job.send_error_email_to_va_ops(exception)
  end

  retry_on(FileUploadError, wait: :exponentially_longer) do |job, exception|
    File.delete(tmp_location) if File.exist?(tmp_location)
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")
    extra = {
      application: job.class.app_name.to_s,
      hearing_id: job.hearing.id,
      file_name: job.file_name,
      job_id: job.job_id
    }
    Raven.capture_exception(exception, extra: extra)
  end

  discard_on(FileNameError) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) discarded with error: #{exception}")
    job.send_error_email_to_va_ops(exception)
  end

  # Purpose: Downloads audio (mp3), video (mp4), or transcript (vtt) file from Webex temporary download link
  #
  # Params: download_link - string, URI for temporary download link
  #         file_name - string, to be parsed for appeal/hearing identifiers
  def perform(download_link:, file_name:)
    ensure_current_user_is_set
    @file_name = file_name
    ensure_hearing_held
    @transcription_file = find_or_create_transcription_file

    download_file_to_tmp(download_link)
    upload_file_to_s3
  end

  # Purpose: Removes temporary file (if it exists) from tmp folder after job success/fails
  #
  # Note: Public method to provide access during job retry
  #
  # Returns: integer value of 1 if file deleted, nil if file not found
  def clean_up_tmp_location
    File.delete(tmp_location) if File.exist?(tmp_location)
  end

  # Purpose: Hearing for which the transcription was created  #
  #
  # Note: Public method to provide access during job retry
  #
  # Returns: Hearing object
  def hearing
    @hearing ||= parse_hearing
  end

  # Purpose: Sends email to Va Operations Team when download fails or hearing disposition not set to held
  #
  # Note: Public method to provide access during job retry
  def send_error_email_to_va_ops(_error)
    # To Be Implemented
    Rails.logger.info("Sending email to Va Operations Team...")
  end

  private

  # Purpose: Downloads file from temporary download link provided by
  #          GetRecordingDetailsJob. Update file status of transcription file depending on download success/failure.
  #
  # Params: download_link - string, URI for temporary download link
  #         file_name - string, to be parsed for appeal/hearing identifiers
  #
  # Returns: Updated @transcription_file
  def download_file_to_tmp(link)
    return if File.exist?(tmp_location)

    begin
      URI.open(link) do |download|
        IO.copy_stream(download, tmp_location)
      end
      update_file_after_download(status: :success, date: Time.zone.now)
    rescue OpenURI::HTTPError => error
      clean_up_tmp_location
      update_file_after_download(status: :failure)
      raise FileDownloadError, "Webex temporary download link responded with #{error.message}"
    end
  end

  # Purpose: Uploads file from tmp directory to s3 location
  #
  # Returns: Updated @transcription_file
  def upload_file_to_s3
    begin
      S3Service.store_file(s3_location, tmp_location, :filepath)
      clean_up_tmp_location
      log_info(s3_success_message)
      update_file_after_upload(status: :success, aws_link: s3_location, date: Time.zone.now)
    rescue Aws::S3::Errors::ServiceError => error
      # In case of S3 upload failure, don't delete file from tmp in case it can be retrieved on retry
      update_file_after_upload(status: :failure)
      raise FileUploadError, "Amazon S3 service responded with #{error.message}"
    end
  end

  # Purpose: Location of temporary file in tmp/transcription_files/<file_type> folder
  #
  # Returns: string, folder path
  def tmp_location
    File.join(Rails.root, "tmp", "transcription_files", file_type, file_name)
  end

  # Purpose: Location of uploaded file in s3
  #
  # Returns: string, s3 filepath
  def s3_location
    folder_name + "/" + S3_SUB_FOLDERS[file_type.to_sym] + "/" + file_name
  end

  # Purpose: Folder name in s3 depending on Rails environment
  #
  # Returns: string, folder name
  def folder_name
    (Rails.deploy_env == :prod) ? S3_SUB_BUCKET : "#{S3_SUB_BUCKET}-#{Rails.deploy_env}"
  end

  # Purpose: Builds on successful upload to S3
  #
  # Returns: string
  def s3_success_message
    "TranscriptionFile (id: #{@transcription_file.id}, file_name: '#{file_name}')" \
    "successfully uploaded to S3 location: '#{@transcription_file.aws_link}'"
  end

  # Purpose: Either mp3 (audio), mp4 (video), or vtt (transcript)
  #
  # Returns: string, file type
  def file_type
    file_name.split(".").last
  end

  # Purpose: Determines if file type parsed from file name is valid
  #
  # Returns: boolean
  def file_type_valid?
    return true if VALID_FILE_TYPES.include?(file_type)

    fail FileNameError, "Invalid file type of '.#{file_type}'"
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
      raise FileNameError, "File name '#{file_name}' missing sufficient hearing identifiers"
    end
  end

  # Purpose: If disposition of hearing is not marked as held, sends email to VA Operations Team and continues with
  #          download
  def ensure_hearing_held
    return if hearing.held?

    error = HearingAssociationError.new("Disposition for hearing (docket numner #{docket_number} not set to held")
    Rails.logger.warn(error)
    send_error_email_to_va_ops(error)
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
      file.file_type = file_type if file_type_valid?
      file.created_by_id = RequestStore[:current_user].id
    end
  end

  # Purpose: Updates the @transcription_file with success or failure status after download completes. If download
  #          successful, updates date_receipt_webex.
  #
  # Returns: TranscriptionFile object
  def update_file_after_download(status:, date: nil)
    @transcription_file.update!(
      file_status: Constants.TRANSCRIPTION_FILE_STATUSES.retrieval.send(status),
      date_receipt_webex: date,
      updated_by_id: RequestStore[:current_user].id
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
      date_upload_aws: date,
      updated_by_id: RequestStore[:current_user].id
    )
  end

  # Purpose: Logging info messages to the console
  def log_info(message)
    Rails.logger.info(message)
  end
end
