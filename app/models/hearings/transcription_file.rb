# frozen_string_literal: true

class TranscriptionFile < CaseflowRecord
  belongs_to :hearing, polymorphic: true

  belongs_to :transcription
  belongs_to :docket

  VALID_FILE_TYPES = %w[mp3 mp4 vtt rtf xls csv].freeze

  validates :file_type, inclusion: { in: VALID_FILE_TYPES, message: "'%<value>s' is not valid" }

  # Purpose: Fetches file from S3
  # Return: The temporary save location of the file
  def fetch_file_from_s3!
    S3Service.fetch_file(aws_link, tmp_location)
    tmp_location
  end

  # Purpose: Uploads transcription file to its corresponding location in S3
  def upload_to_s3!
    TranscriptionFileUpload.new(self).call
  end

  # Purpose: Converts transcription file from vtt to rtf
  #
  # Returns: string, tmp location of rtf (or xls/csv file if error)
  def convert_to_rtf!
    return unless file_type == "vtt"

    hearing_info = {
      judge: hearing.judge&.full_name,
      appeal_id: hearing.appeal&.veteran_file_number,
      date: hearing.scheduled_for
    }
    file_paths = TranscriptionTransformer.new(tmp_location, hearing_info).call
    update_status!(process: :conversion, status: :success)
    file_paths
  rescue TranscriptionTransformer::FileConversionError => error
    update_status!(process: :conversion, status: :failure)
    raise error, error.message
  end

  # Purpose: Maps file handling process with associated field to update
  DATE_FIELDS = {
    retrieval: :date_receipt_webex,
    upload: :date_upload_aws,
    conversion: :date_converted
  }.freeze

  # Purpose: Updates statue of transcription file after completion of process. If process was success, updates
  #          associated date field on record.
  #
  # Params: process - symbol, used to map process with associated file status and date field
  #         status - symbol, either :success or :failure
  #         aws_link - string, optional argument of AWS S3 location
  #
  # Returns: Updated transcription file record
  def update_status!(process:, status:, upload_link: nil)
    params = {
      file_status: Constants.TRANSCRIPTION_FILE_STATUSES.send(process).send(status),
      updated_by_id: RequestStore[:current_user].id
    }
    params[:aws_link] = upload_link if upload_link
    params[DATE_FIELDS[process]] = Time.zone.now if status == :success
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
