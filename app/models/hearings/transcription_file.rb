# frozen_string_literal: true

class TranscriptionFile < CaseflowRecord
  include BelongsToPolymorphicAppealConcern
  belongs_to_polymorphic_appeal :appeal
  belongs_to :transcription
  belongs_to :docket

  VALID_FILE_TYPES = %w[mp3 mp4 vtt rtf xls csv].freeze

  validates :file_type, inclusion: { in: VALID_FILE_TYPES, message: "'%<value>s' is not valid" }

  # Purpose: Uploads transcription file to its corresponding location in S3
  def upload_to_s3
    UploadTranscriptionFileToS3.new(self).call
  end

  # Purpose: Converts transcription file from vtt to rtf
  #
  # Returns: string, tmp location of rtf (or xls/csv file if error)
  def convert_to_rtf(hearing_info)
    return unless file_type == "vtt"

    rtf_file_path = TranscriptionTransformer.new(tmp_location, hearing_info).call
    update_conversion_status!(:success)
    rtf_file_path
  rescue TranscriptionTransformer::FileConversionError => error
    update_conversion_status!(:failure)
    raise error, error.message
  end

  # Purpose: Updates with success or failure status after download completes. If download
  #          successful, updates date_receipt_webex.
  #
  # Returns: TranscriptionFile object
  def update_download_status!(status)
    update!(
      file_status: Constants.TRANSCRIPTION_FILE_STATUSES.retrieval.send(status),
      date_receipt_webex: (status == :success) ? Time.zone.now : nil,
      updated_by_id: RequestStore[:current_user].id
    )
  end

  # Purpose: Updates with success or failure status after upload to s3 completes. If upload
  #          successful, updates date_upload_aws and aws_link.
  #
  # Returns: TranscriptionFile object
  def update_upload_status!(status:, aws_link: nil)
    update!(
      file_status: Constants.TRANSCRIPTION_FILE_STATUSES.upload.send(status),
      aws_link: aws_link,
      date_upload_aws: (status == :success) ? Time.zone.now : nil,
      updated_by_id: RequestStore[:current_user].id
    )
  end

  # Purpose: Updates with success or failure status after conversion from vtt to rtf completes. If download
  #          successful, updates date_converted.
  #
  # Returns: TranscriptionFile object
  def update_conversion_status!(status)
    update!(
      file_status: Constants.TRANSCRIPTION_FILE_STATUSES.conversion.send(status),
      date_converted: (status == :success) ? Time.zone.now : nil,
      updated_by_id: RequestStore[:current_user].id
    )
  end

  # Purpose: Location of temporary file in tmp/transcription_files/<file_type> folder
  #
  # Returns: string, folder path
  def tmp_location
    File.join(Rails.root, "tmp", "transcription_files", file_type, file_name)
  end

  # Purpose: Removes temporary file (if it exists) from corresponding tmp folder
  #
  # Returns: integer value of 1 if file deleted, nil if file not found
  def clean_up_tmp_location
    File.delete(tmp_location) if File.exist?(tmp_location)
  end
end
