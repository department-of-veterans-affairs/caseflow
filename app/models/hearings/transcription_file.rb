# frozen_string_literal: true

class TranscriptionFile < CaseflowRecord
  belongs_to :hearing, polymorphic: true

  belongs_to :transcription
  belongs_to :docket

  belongs_to :locked_by, class_name: "User"

  VALID_FILE_TYPES = %w[mp3 mp4 vtt rtf xls csv zip doc pdf].freeze

  validates :file_type, inclusion: { in: VALID_FILE_TYPES, message: "'%<value>s' is not valid" }

  scope :filterable_values, lambda {
    select("
      transcription_files.*,
      (CASE WHEN aod_based_on_age IS NOT NULL THEN aod_based_on_age ELSE false END) AS aod_based_on_age,
      (CASE WHEN aodm.granted IS NOT NULL THEN aodm.granted ELSE false END) AS aod_motion_granted,
      scheduled_for,
      concat_ws(' ',
        CASE WHEN aodm.granted OR aod_based_on_age THEN 'AOD' END,
        CASE WHEN appeals.stream_type IS NOT NULL THEN appeals.stream_type ELSE 'original' END
        ) AS sortable_case_type
    ")
      .joins("LEFT OUTER JOIN hearings ON hearings.id = transcription_files.hearing_id AND
        transcription_files.hearing_type = 'Hearing'")
      .joins("LEFT OUTER JOIN legacy_hearings ON legacy_hearings.id = transcription_files.hearing_id AND
        transcription_files.hearing_type = 'LegacyHearing'")
      .joins("LEFT OUTER JOIN appeals ON hearings.appeal_id = appeals.id AND
        transcription_files.hearing_type = 'Hearing'")
      .joins("LEFT OUTER JOIN legacy_appeals ON hearings.appeal_id = legacy_appeals.id AND
        transcription_files.hearing_type = 'LegacyHearing'")
      .joins("LEFT OUTER JOIN advance_on_docket_motions AS aodm ON
        ((aodm.appeal_id = appeals.id AND aodm.appeal_type = 'Appeal') OR
        (aodm.appeal_id = legacy_appeals.id AND aodm.appeal_type = 'LegacyAppeal'))
        AND aodm.granted = true")
      .joins("LEFT OUTER JOIN hearing_days ON hearing_days.id = hearings.hearing_day_id OR
        hearing_days.id = legacy_hearings.hearing_day_id")
  }

  scope :unassigned, -> { where(file_status: Constants.TRANSCRIPTION_FILE_STATUSES.upload.success) }

  scope :completed, lambda {
    where(file_status: ["Successful upload (AWS)", "Failed Retrieval (BOX)", "Overdue"])
  }

  scope :filter_by_hearing_type, ->(values) { where("hearing_type IN (?)", values) }

  scope :filter_by_status, ->(values) { where("file_status IN (?)", values) }

  scope :filter_by_types, lambda { |values|
    filter_parts = []
    stream_types = []
    values.each do |value|
      if value == "AOD"
        filter_parts <<
          "(aod_based_on_age = true OR aodm.granted = true)"
      else
        stream_types << value
        filter_parts <<
          "((hearing_type = 'Hearing' AND stream_type IN (?)) OR hearing_type = 'LegacyHearing')"
      end
    end
    where(filter_parts.join(" OR "), stream_types)
  }

  scope :filter_by_hearing_dates, lambda { |values|
    mode = values[0]
    if mode == "between"
      start_date = values[1] + " 00:00:00"
      end_date = values[2] + " 23:59:59"
      where(Arel.sql("scheduled_for >= '" + start_date + "' AND scheduled_for <= '" + end_date + "'"))
    elsif mode == "before"
      date = values[1] + " 00:00:00"
      where(Arel.sql("scheduled_for < '" + date + "'"))
    elsif mode == "after"
      date = values[1] + " 23:59:59"
      where(Arel.sql("scheduled_for > '" + date + "'"))
    elsif mode == "on"
      start_date = values[1] + " 00:00:00"
      end_date = values[1] + " 23:59:59"
      where(Arel.sql("scheduled_for >= '" + start_date + "' AND scheduled_for <= '" + end_date + "'"))
    end
  }

  scope :order_by_id, ->(direction) { order(Arel.sql("id " + direction)) }
  scope :order_by_hearing_date, ->(direction) { order(Arel.sql("scheduled_for " + direction)) }
  scope :order_by_hearing_type, ->(direction) { order(Arel.sql("hearing_type " + direction)) }
  scope :order_by_case_type, ->(direction) { order(Arel.sql("sortable_case_type " + direction)) }

  scope :locked, -> { where(locked_at: (Time.now.utc - 2.hours)..Time.now.utc) }

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
    retrieval: :date_receipt_recording,
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

  # Purpose: Get hearing date from associated hearing_day
  #
  # Returns: string, a date formated like mm/dd/yyyy
  def hearing_date
    scheduled_for.to_formatted_s(:short_date)
  end

  # Purpose: Returns advance on docket status from associated advance_on_docket_motion
  #
  # Returns: boolean, true of either age based is true or motion granted
  def advanced_on_docket?
    aod_based_on_age || aod_motion_granted
  end

  # Purpose: Returns a formatted stream_type from an AMA appeal
  #
  # Returns: string, defaults to Original if not AMA
  def case_type
    (hearing.appeal.try(:stream_type) || "Original").capitalize
  end

  # Purpose: Returns the external appeal id from an AMA appeal or Legacy appeal
  #
  # Returns: string, defaults to blank of not AMA
  def external_appeal_id
    hearing.appeal.external_id
  end

  # Purpose: Returns a formatted value containing the veteral name and file number
  #
  # Returns: string
  def case_details
    appellant_name = hearing.appeal.appellant_or_veteran_name
    file_number = hearing.appeal.veteran_file_number
    "#{appellant_name} (#{file_number})"
  end

  # Purpose: Returns true if record is not locked, was locked by user_id, or locked more than two hours ago
  def lockable?(user_id)
    !locked_by_id || locked_by_id == user_id || locked_at < Time.now.utc - 2.hours
  end

  def self.reset_files(task_number)
    transcription = Transcription.find_by(task_number: task_number)
    return unless transcription

    transcription_files = Hearings::TranscriptionFile.where(transcription_id: transcription.id)

    transcription_files.each do |file|
      file.update(file_status: "Successful upload (AWS)", date_upload_box: nil)
    end
  end
end
