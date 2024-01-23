# frozen_string_literal: true

require "webvtt"

# Job for converting VTT transcription files to RTF
class Hearings::RTFConversionJob < CaseflowJob
  queue_with_priority :low_priority

  # Sub folder name
  S3_FOLDER_NAME = "vaec-appeals-caseflow"

  def initialize
    @logs = ["\nHearings::RTFConversion Log"]
    @folder_name = (Rails.deploy_env == :prod) ? S3_FOLDER_NAME : "#{S3_FOLDER_NAME}-#{Rails.deploy_env}"
    super
  end

  # Get transcription files waiting for file conversion
  def files_waiting_for_conversion
    TranscriptionFile.where(date_converted: nil)
  end

  # Retrieve files from the s3 bucket
  def retreive_files_from_s3
    s3 = Aws::S3::Client.new
    resp = s3.get_object(bucket: @folder_name, key:'object-key')
  end

  # Convert vtt file to rtf
  def convert_to_rtf

  end

  # Create a transcription file record
  def create_transcription_file

  end

  # Upload file to S3 bucket
  def upload_to_s3

  end

  # Create an xls file for errors
  def create_xls_file

  end

end
