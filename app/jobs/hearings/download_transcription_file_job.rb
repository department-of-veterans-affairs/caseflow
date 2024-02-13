# frozen_string_literal: true

require "open-uri"
require "csv"

# Downloads transcription file from Webex using temporary download link and uploads to S3
# - Download link passed to this job from GetRecordingDetailsJob
# - File type either audio (mp3), video (mp4), or vtt (transcript)

class Hearings::DownloadTranscriptionFileJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  attr_reader :file_name, :transcription_file

  CONVERSION_MAP = {
    vtt: "rtf",
    mp4: "mp3"
  }.freeze

  class FileNameError < StandardError; end
  class FileDownloadError < StandardError; end
  class HearingAssociationError < StandardError; end

  retry_on(FileDownloadError, wait: 5.minutes) do |job, exception|
    # TO IMPLEMENT: SEND EMAIL TO VA OPS TEAM
    job.log_error(exception)
  end

  retry_on(UploadTranscriptionFileToS3::FileUploadError, wait: :exponentially_longer) do |job, exception|
    job.transcription_file.clean_up_tmp_location
    job.log_error(exception)
  end

  retry_on(Caseflow::Error::FileConversionError, wait: 10.seconds) do |job, exception|
    job.build_csv_and_upload_to_s3!(exception)
    job.transcription_file.clean_up_tmp_location
    # TO IMPLEMENT: SEND EMAIL TO VA OPS TEAM
    job.log_error(exception)
  end

  discard_on(FileNameError) do |job, error|
    # TO IMPLEMENT: SEND EMAIL TO VA OPS TEAM
    Rails.logger.error("#{job.class.name} (#{job.job_id}) discarded with error: #{error}")
  end

  # Purpose: Downloads audio (mp3), video (mp4), or transcript (vtt) file from Webex temporary download link and
  #          uploads the file to corresponding S3 loccation. If file is vtt, kicks off conversion of vtt to rtf
  #          and uploads rtf file to S3.
  def perform(download_link:, file_name:, conversion_needed: false)
    ensure_current_user_is_set
    @file_name = file_name
    @conversion_needed = conversion_needed
    @transcription_file = find_or_create_transcription_file
    ensure_hearing_held

    download_file_to_tmp!(download_link)
    @transcription_file.upload_to_s3! if @transcription_file.date_upload_aws.nil?
    convert_file_and_upload_to_s3! if conversion_request_valid?
    @transcription_file.clean_up_tmp_location
  end

  # Purpose: Logs error and captures exception
  #
  # Note: Public method to provide access during job retry
  #
  # Params: exception - Error object
  #         send_email - boolean, whether or not error should be emailed to VA Operations Team
  def log_error(error)
    Rails.logger.error("#{self.class.name} failed with error: #{error}")
    extra = {
      application: self.class.name,
      hearing_id: hearing.id,
      file_name: file_name,
      job_id: job_id
    }
    Raven.capture_exception(error, extra: extra)
  end

  # Purpose: If retries of conversion of vtt to rtf fail, builds csv which captures error and details of vtt file.
  #          Uploads csv file to S3.
  #
  # Params: exception - Error object
  def build_csv_and_upload_to_s3!(exception)
    build_csv_from_error(exception)
    csv_file = find_or_create_transcription_file(file_name.gsub("vtt", "csv"))
    csv_file.upload_to_s3!
    csv_file.clean_up_tmp_location
  end

  private

  # Purpose: Downloads file from temporary download link provided by
  #          GetRecordingDetailsJob. Update file status of transcription file depending on download success/failure.
  #
  # Params: download_link - string, URI for temporary download link
  #         file_name - string, to be parsed for appeal/hearing identifiers
  #
  # Returns: Updated @transcription_file
  def download_file_to_tmp!(link)
    return if File.exist?(@transcription_file.tmp_location)

    URI(link).open do |download|
      IO.copy_stream(download, @transcription_file.tmp_location)
    end
    @transcription_file.update_status!(process: :retrieval, status: :success)
    log_info("File #{file_name} successfully downloaded from Webex. Uploading to S3...")
  rescue OpenURI::HTTPError => error
    @transcription_file.update_status!(process: :retrieval, status: :failure)
    @transcription_file.clean_up_tmp_location
    raise FileDownloadError, "Webex temporary download link responded with error: #{error}"
  end

  # Purpose: Hearing for which the Webex conference was held
  #
  # Note: Public method to provide access during job retry
  #
  # Returns: Hearing object
  def hearing
    @hearing ||= parse_hearing
  end

  # Purpose: Parses hearing details from identifiers present in file name
  #
  # Returns: Hearing object or error if hearing not able to be parsed or found
  def parse_hearing
    identifiers = file_name.split(".").first
    hearing_id = identifiers.split("_")[1]
    hearing_type = identifiers.split("_")[2]
    hearing_type.constantize.find(hearing_id)
  rescue StandardError => error
    raise FileNameError, "Encountered error #{error} when attempting to parse hearing from file name '#{file_name}'"
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
    hearing.docket_number
  end

  # Purpose: Finds existing transcription file record if job previously failed and retry initiated. Otherewise, creates
  #          new record.
  #
  # Params: file_name_arg - string, optional parameter with default value of file name attribute. Allows for method to
  #                         be reused when converting vtt file to rtf.
  #
  # Returns: TranscriptionFile object
  def find_or_create_transcription_file(file_name_arg = file_name)
    TranscriptionFile.find_or_create_by(
      file_name: file_name_arg,
      appeal_id: appeal&.id,
      appeal_type: appeal&.class&.name,
      docket_number: docket_number
    ) do |file|
      file.file_type = file_name_arg.split(".").last
      file.created_by_id = RequestStore[:current_user].id
      file.save!
    end
  rescue ActiveRecord::RecordInvalid => error
    raise FileNameError, error
  end

  # Purpose: File type of transcription_file
  #
  # Returns: string, file type
  def raw_file_type
    @raw_file_type ||= @transcription_file.file_type
  end

  # Purpose: File type of transcription_file after conversion, if conversion necessary
  #
  # Returns: string, file type or nil
  def conversion_type
    @conversion_type ||= (CONVERSION_MAP || {})[raw_file_type.to_sym]
  end

  # Purpose: Determines if job should proceed with conversion and prevents accidental conversion request of
  #          unconvertible file type
  #
  # Returns: boolean
  def conversion_request_valid?
    raw_file_type == "vtt" || (@conversion_needed && conversion_type.present?)
  end

  # Purpose: Converts raw transcription file, creates new record for converted transcription file, and uploads
  #          converted file to S3
  #
  # Returns: integer value of 1 if tmp file deleted after successful upload
  def convert_file_and_upload_to_s3!
    log_info("Converting file #{file_name} to #{conversion_type}...")
    output_path = convert_file
    converted_file_name = output_path.split("/").last
    converted_file = find_or_create_transcription_file(converted_file_name)

    log_info("Successfully converted #{file_name} to #{conversion_type}. Uploading to S3...")
    converted_file.upload_to_s3!
    converted_file.clean_up_tmp_location
  end

  # Purpose: Converts transcription file to appropriate file type
  #
  # Returns: string, output path of successfully converted file
  def convert_file
    case raw_file_type
    when "vtt"
      @transcription_file.convert_to_rtf!
    when "mp4"
      @transcription_file.convert_to_mp3!
    end
  end

  # Purpose: If retries of conversion of vtt to rtf fail, builds csv which captures error and details of vtt file
  #
  # Params: error - Error object
  def build_csv_from_error(error)
    return unless raw_file_type == "vtt"

    timestamp = Time.zone.now.to_s.sub("\sUTC", "")
    file_date = File.ctime(@transcription_file.tmp_location).to_s.split(" ").first
    csv_tmp_location = @transcription_file.tmp_location.gsub("vtt", "csv")
    header = %w[file_name file_date section_timestamp error_encountered]
    CSV.open(csv_tmp_location, "w") do |writer|
      writer << header
      writer << [file_name, file_date, timestamp, error.to_s]
    end
  end

  # Purpose: If disposition of associated hearing is not marked as held, sends email to VA Operations Team and
  #          continues with download job
  def ensure_hearing_held
    return if hearing.held?

    msg = "Download of Webex transcription files initiated for hearing (docket ##{docket_number}) successful, " \
          "but hearing's disposition not set to held."
    Rails.logger.warn(HearingAssociationError.new(msg))
    # TO IMPLEMENT: SEND EMAIL TO VA OPS TEAM
  end

  # Purpose: Logs message
  #
  # Params: message - string
  def log_info(message)
    Rails.logger.info(message)
  end
end
