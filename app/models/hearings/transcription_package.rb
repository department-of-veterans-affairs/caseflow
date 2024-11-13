# frozen_string_literal: true

class TranscriptionPackage < CaseflowRecord
  belongs_to :contractor, class_name: "TranscriptionContractor"
  has_many :transcription_package_hearings
  has_many :hearings, through: :transcription_package_hearings
  has_many :transcription_package_legacy_hearings
  has_many :legacy_hearings, through: :transcription_package_legacy_hearings
  has_many :transcriptions, foreign_key: :task_number, primary_key: :task_number

  scope :filter_by_date, lambda { |values, field_name|
    mode = values[0]
    if mode == "between"
      start_date = values[1] + " 00:00:00"
      end_date = values[2] + " 23:59:59"
      where(Arel.sql(field_name + " >= '" + start_date + "' AND " + field_name + " <= '" + end_date + "'"))
    elsif mode == "before"
      date = values[1] + " 00:00:00"
      where(Arel.sql(field_name + " < '" + date + "'"))
    elsif mode == "after"
      date = values[1] + " 23:59:59"
      where(Arel.sql(field_name + " > '" + date + "'"))
    elsif mode == "on"
      start_date = values[1] + " 00:00:00"
      end_date = values[1] + " 23:59:59"
      where(Arel.sql(field_name + " >= '" + start_date + "' AND " + field_name + " <= '" + end_date + "'"))
    end
  }

  scope :filter_by_contractor, ->(values) { where("transcription_contractors.name IN (?)", values) }

  scope :filter_by_status, ->(values) { where(status: values) }

  scope :search, lambda { |search|
    # find transcription files that match the search
    transcription_ids = TranscriptionFile
      .filterable_values.search(search).pluck(:transcription_id)
    if transcription_ids.empty?
      transcription_ids = [-1]
    end

    # find task numbers for those transcriptions
    task_numbers = Transcription.where(id: transcription_ids).pluck(:task_number)
    if task_numbers.empty?
      task_numbers = [-1]
    end

    where(task_number: task_numbers)
  }

  scope :order_by_field, ->(direction, field_name) { order(Arel.sql(field_name + " " + direction)) }

  scope :with_status_overdue_or_sent, -> { joins(:contractor).where(status: ["Overdue", "Successful Upload (BOX)"]) }

  def contractor_name
    contractor&.name
  end

  def all_hearings
    (hearings + legacy_hearings).map { |hearing| serialize_hearing(hearing) }
  end

  def formatted_date_upload_box
    format_date_for_table(date_upload_box)
  end

  def formatted_returned_at
    format_date_for_table(returned_at)
  end

  def contents_count
    (hearings + legacy_hearings).length
  end

  def self.cancel_by_task_number(task_number)
    find_by(task_number: task_number)&.update(status: "cancelled")
  end

  private

  def format_date_for_table(date)
    date.utc.strftime("%-m/%-d/%Y")
  end

  def format_case_details(hearing)
    file_number = format_file_number(hearing.veteran_file_number)
    full_name = format_full_name(hearing.veteran_first_name, hearing.veteran_last_name)
    [full_name, file_number].join(" ")
  end

  def format_file_number(file_number)
    "(#{file_number})"
  end

  def format_full_name(first_name, last_name)
    "#{first_name} #{last_name}"
  end

  def serialize_hearing(hearing)
    {
      docketNumber: hearing.docket_number,
      caseDetails: format_case_details(hearing),
      hearingType: hearing.class.name,
      appealId: hearing.appeal.external_id
    }
  end
end
