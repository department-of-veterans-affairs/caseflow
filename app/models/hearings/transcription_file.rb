# frozen_string_literal: true

class TranscriptionFile < CaseflowRecord
  include BelongsToPolymorphicAppealConcern
  belongs_to_polymorphic_appeal :appeal
  belongs_to :transcription
  belongs_to :docket

  VALID_FILE_TYPES = %w[mp3 mp4 vtt rtf xls csv].freeze

  validates :file_type, inclusion: { in: VALID_FILE_TYPES, message: "'%<value>s' is not valid" }

  FILE_STATUSES = {
    retrieval: {
      success: "Successful retrieval (Webex)",
      failure: "Failed retrieval (Webex)"
    },
    upload: {
      success: "Successful upload (AWS)",
      failure: "Failed upload (AWS)"
    },
    conversion: {
      success: "Successful conversion",
      failure: "Failed conversion"
    }
  }.freeze

  DATE_FIELDS = {
    retrieval: :date_receipt_webex,
    upload: :date_upload_aws,
    conversion: :date_converted
  }.freeze

  # Purpose: Uploads transcription file to its corresponding location in S3
  def upload_to_s3
    UploadTranscriptionFileToS3.new(self).call
  end

  # Purpose: Converts transcription file from vtt to rtf
  #
  # Returns: string, tmp location of rtf (or xls/csv file if error)
  def convert_to_rtf
    return unless file_type == "vtt"

    rtf_file_path = TranscriptionTransformer.new(tmp_location).call
    update_status!(process: :conversion, status: :success)
    rtf_file_path
  rescue Caseflow::Error::FileConversionError => error
    update_status!(process: :conversion, status: :failure)
    raise error, error.message
  end

  # Purpose: Converts transcription file from mp4 to mp3 if necessary
  #
  # Note: We expect Webex to return a downloadable mp3 file, in which case it's unnecessary to convert mp4 to mp3
  #
  # Returns: string, tmp location of mp3
  def convert_to_mp3
    return unless file_type == "mp4"

    mp3_file_path = VideoToAudioFileConverter.new(tmp_location).call
    update_status!(process: :conversion, status: :success)
    mp3_file_path
  rescue Caseflow::Error::FileConversionError => error
    update_status!(process: :conversion, status: :failure)
    raise error, error.message
  end

  # Purpose: Updates statue of transcription file after completion of process. If process was success, updates
  #          associated date field on record.
  #
  # Params: process - symbol, used to map process with associated file status and date field
  #         status - symbol, either :success or :failure
  #         aws_link - string, optional argument of AWS S3 location
  #
  # Returns: Updated transcription file record
  def update_status!(process:, status:, aws_link: nil)
    params = {
      file_status: FILE_STATUSES[process][status],
      aws_link: aws_link,
      updated_by_id: RequestStore[:current_user].id
    }
    date_field_to_update = DATE_FIELDS[process]
    params[date_field_to_update] = Time.zone.now if status == :success
    update!(params)
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
