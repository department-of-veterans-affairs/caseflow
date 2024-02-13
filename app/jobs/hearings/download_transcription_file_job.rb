# frozen_string_literal: true

require "open-uri"

# Downloads transcription file from Webex using temporary download link and uploads to S3
# - Download link passed to this job from GetRecordingDetailsJob
# - File type either audio (mp3), video (mp4), or vtt (transcript)

class Hearings::DownloadTranscriptionFileJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority

  attr_reader :file_name, :transcription_file

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

  retry_on(TranscriptionTransformer::FileConversionError, wait: 10.seconds) do |job, exception|
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
  def perform(download_link:, file_name:)
    ensure_current_user_is_set
    @file_name = file_name
    @transcription_file = find_or_create_transcription_file
    ensure_hearing_held
    download_file_to_tmp(download_link)
    @transcription_file.upload_to_s3 if @transcription_file.date_upload_aws.nil?
    maybe_convert_vtt_to_rtf_and_upload_to_s3
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

  private

  # Purpose: Downloads file from temporary download link provided by
  #          GetRecordingDetailsJob. Update file status of transcription file depending on download success/failure.
  #
  # Params: download_link - string, URI for temporary download link
  #         file_name - string, to be parsed for appeal/hearing identifiers
  #
  # Returns: Updated @transcription_file
  def download_file_to_tmp(link)
    return if File.exist?(@transcription_file.tmp_location)

    URI(link).open do |download|
      IO.copy_stream(download, @transcription_file.tmp_location)
    end
    @transcription_file.update_download_status!(:success)
    log_info("File #{file_name} successfully downloaded from Webex. Uploading to S3...")
  rescue OpenURI::HTTPError => error
    @transcription_file.update_download_status!(:failure)
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

  # Purpose: If file is vtt, converts to rtf and uploads the rtf file to S3. If any errors, builds xls/csv file to
  #          record error and uploads error file to S3.
  def maybe_convert_vtt_to_rtf_and_upload_to_s3
    return unless @transcription_file.file_type == "vtt"

    hearing_info = {
      judge: hearing.judge&.full_name,
      appeal_id: hearing.appeal&.veteran_file_number,
      date: hearing.scheduled_for
    }

    log_info("Converting file #{file_name} to rtf...")
    file_paths = @transcription_file.convert_to_rtf(hearing_info)
    file_paths.each do |path|
      file_name = path.split("/").last
      file = find_or_create_transcription_file(file_name)
      if path.match?("rtf")
        log_info("Successfully converted #{file_name} to rtf. Uploading to S3...")
      else
        log_info("Errors were found during conversion. Uploading csv to S3...")
      end
      file.upload_to_s3
      file.clean_up_tmp_location
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
