# frozen_string_literal: true

require "open-uri"

# Downloads transcription file from Webex using temporary download link and uploads to S3
# - Download link passed to this job from FetchRecordingDetailsJob
# - File type either audio (mp3), video (mp4), or vtt (transcript)

class Hearings::DownloadTranscriptionFileJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet
  include Hearings::SendTranscriptionIssuesEmail

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  attr_reader :file_name, :transcription_file

  class FileNameError < StandardError; end
  class FileDownloadError < StandardError; end
  class HearingAssociationError < StandardError; end
  class NoDownloadLinkError < StandardError; end

  retry_on(FileDownloadError, wait: 5.minutes) do |job, exception|
    details_hash = {
      temporary_download_link: { link: job.arguments.first[:download_link] },
      error: { type: "download" },
      provider: "webex"
    }
    error_details = job.build_error_details(exception, details_hash)
    job.log_download_error(exception)
    job.send_transcription_issues_email(error_details)
  end

  retry_on(TranscriptionFileUpload::FileUploadError, wait: :exponentially_longer) do |job, exception|
    details_hash = { error: { type: "upload" }, provider: "S3" }
    error_details = job.build_error_details(exception, details_hash)
    job.transcription_file.clean_up_tmp_location
    job.log_download_error(exception)
    job.send_transcription_issues_email(error_details)
  end

  retry_on(TranscriptionTransformer::FileConversionError, wait: 10.seconds) do |job, exception|
    job.transcription_file.clean_up_tmp_location
    details_hash = { error: { type: "conversion" }, conversion_type: "rtf" }
    error_details = job.build_error_details(exception, details_hash)
    job.log_download_error(exception)
    job.send_transcription_issues_email(error_details)
  end

  discard_on(FileNameError) do |job, exception|
    details_hash = {
      error: { type: "download" },
      provider: "webex",
      reason: "Unable to parse hearing information from file name: #{job.file_name}",
      expected_file_name_format: "[docket_number]_[internal_id]_[hearing_type].[file_type]"
    }
    error_details = job.build_error_details(exception, details_hash)
    job.log_download_error(exception)
    job.send_transcription_issues_email(error_details)
  end

  discard_on(NoDownloadLinkError) do |job, exception|
    job.log_error(exception)
  end

  # Purpose: Downloads audio (mp3), video (mp4), or transcript (vtt) file from Webex temporary download link and
  #          uploads the file to corresponding S3 location. If file is vtt, kicks off conversion of vtt to rtf
  #          and uploads rtf file to S3.
  def perform(download_link:, file_name:)
    fail NoDownloadLinkError if !download_link

    ensure_current_user_is_set
    @file_name = file_name
    @transcription_file ||= find_or_create_transcription_file
    ensure_hearing_held
    if should_download?
      download_file_to_tmp!(download_link)
      @transcription_file.upload_to_s3!
      convert_to_rtf_and_upload_to_s3! if should_convert_and_upload?
    end
    @transcription_file.clean_up_tmp_location
  end

  # Checks if file is a vtt and was not already converted
  def should_convert_and_upload?
    @transcription_file.file_type == "vtt" && @transcription_file.date_converted.nil?
  end

  # Checks if the file either never started or failed to finish processing
  def should_download?
    file = @transcription_file

    (file.file_type == "vtt" && file.file_status != Constants.TRANSCRIPTION_FILE_STATUSES.conversion.success) ||
      (file.file_type != "vtt" && file.file_status != Constants.TRANSCRIPTION_FILE_STATUSES.upload.success)
  end

  # Purpose: Builds hash of values to be listed in mail template
  #
  # Note: Public method to provide access during job retry
  #
  # Params: error - Instance of error
  #         details_hash - hash of attributes and values to be listed in mail template
  #
  # Returns: The hash for details on the error
  def build_error_details(error, details_hash)
    details_hash.merge(
      docket_number: !file_name_error?(error) ? hearing.docket_number : nil,
      appeal_id: !file_name_error?(error) ? hearing.appeal.external_id : nil,
      error: details_hash[:error].merge(
        explanation: build_error_explanation(details_hash)
      )
    )
  end

  # Purpose: Logs error and captures exception
  #
  # Note: Public method to provide access during job retry
  #
  # Params: error - Error object
  def log_download_error(error)
    extra = {
      application: self.class.name,
      hearing_id: !file_name_error?(error) ? hearing.id : nil,
      file_name: file_name,
      job_id: job_id
    }
    log_error(error, extra: extra)
  end

  private

  # Purpose: Downloads file from temporary download link provided by
  #          FetchRecordingDetailsJob. Update file status of transcription file depending on download success/failure.
  #
  # Params: download_link - string, URI for temporary download link
  #         file_name - string, to be parsed for hearing identifiers
  #
  # Returns: Updated @transcription_file
  def download_file_to_tmp!(link)
    transcription_file = @transcription_file
    return if File.exist?(transcription_file.tmp_location)

    URI(link).open do |download|
      IO.copy_stream(download, transcription_file.tmp_location)
    end
    transcription_file.update_status!(process: :retrieval, status: :success)
    log_info("File #{file_name} successfully downloaded from Webex. Uploading to S3...")
  rescue OpenURI::HTTPError => error
    transcription_file.update_status!(process: :retrieval, status: :failure)
    transcription_file.clean_up_tmp_location
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
    hearing_type = identifiers.split("_").last.split("-").first
    hearing_type.constantize.find(hearing_id)
  rescue StandardError => error
    raise FileNameError, "Encountered error #{error} when attempting to parse hearing from file name '#{file_name}'"
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
    Hearings::TranscriptionFile.find_or_create_by(
      file_name: file_name_arg,
      hearing_id: hearing.id,
      hearing_type: hearing.class.name,
      docket_number: docket_number
    ) do |file|
      file.file_type = file_name_arg.split(".").last
      file.created_by_id = RequestStore[:current_user].id
      file.save!
    end
  rescue ActiveRecord::RecordInvalid => error
    raise FileNameError, error
  end

  # Purpose: Converts vtt to rtf, creates new record for converted transcription file, and uploads
  #          converted file to S3
  #
  # Returns: integer value of 1 if tmp file deleted after successful upload
  def convert_to_rtf_and_upload_to_s3!
    log_info("Converting file #{file_name} to rtf...")
    transcription_file = @transcription_file
    file_paths = transcription_file.convert_to_rtf!
    file_paths.each do |file_path|
      output_file_name = file_path.split("/").last
      output_file = find_or_create_transcription_file(output_file_name)
      log_info("Successfully converted #{file_name} to rtf. Uploading #{output_file.file_type} to S3...")
      output_file.upload_to_s3!
      output_file.clean_up_tmp_location
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

  JOB_ACTIONS = {
    download: { verb: "download", direction: "from" },
    upload: { verb: "upload", direction: "to" },
    conversion: { verb: "convert", direction: "to" }
  }.freeze

  # Purpose: Builds error message to be printed in email notifications
  #
  # Params: details_hash - hash of attributes and values to be listed in mail template
  #
  # Returns: String message
  def build_error_explanation(details_hash)
    action = JOB_ACTIONS[details_hash[:error][:type].to_sym]
    action_recipient = details_hash[:provider]&.titlecase || details_hash.delete(:conversion_type)
    file_type = @transcription_file ? "#{@transcription_file.file_type} " : ""

    "#{action[:verb]} a #{file_type}file #{action[:direction]} #{action_recipient}"
  end

  def file_name_error?(error)
    error.is_a?(FileNameError)
  end
end
