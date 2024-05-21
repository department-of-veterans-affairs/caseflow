# frozen_string_literal: true

class TranscriptionFileUpload
  attr_reader :file_name, :file_type

  S3_SUB_BUCKET = "vaec-appeals-caseflow"

  S3_SUB_FOLDERS = {
    mp3: "transcript_audio",
    mp4: "transcript_audio",
    vtt: "transcript_raw",
    rtf: "transcript_text",
    xls: "transcript_text",
    csv: "transcript_text",
    zip: "transcript_text",
    json: "transcript_text"
  }.freeze

  class FileUploadError < StandardError; end

  # Params: transcription_file - TranscriptionFile object
  def initialize(transcription_file)
    @transcription_file = transcription_file
    @file_name = @transcription_file.file_name
    @file_type = @transcription_file.file_type
    @folder_name = (Rails.deploy_env == :prod) ? S3_SUB_BUCKET : "#{S3_SUB_BUCKET}-#{Rails.deploy_env}"
  end

  # Purpose: Uploads transcription file to its corresponding location in S3
  def call
    S3Service.store_file(s3_location, @transcription_file.tmp_location, :filepath)
    @transcription_file.update_status!(process: :upload, status: :success, upload_link: s3_location)
    Rails.logger.info("File #{file_name} successfully uploaded to S3 location: #{s3_location}")
  rescue StandardError => error
    @transcription_file.update_status!(process: :upload, status: :failure)
    raise FileUploadError "Amazon S3 service responded with error: #{error}"
  end

  private

  # Purpose: Location of uploaded file in s3
  #
  # Returns: string, s3 filepath
  def s3_location
    @folder_name + "/" + S3_SUB_FOLDERS[file_type.to_sym] + "/" + file_name
  end
end
