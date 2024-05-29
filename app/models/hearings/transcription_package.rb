# frozen_string_literal: true

class TranscriptionPackage < CaseflowRecord
  belongs_to :contractor, class_name: "TranscriptionContractor"
  has_many :transcription_package_hearings
  has_many :hearings, through: :transcription_package_hearings
  has_many :transcription_package_legacy_hearings
  has_many :legacy_hearings, through: :transcription_package_legacy_hearings

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

  private

  def format_date_for_table(date)
    date.utc.strftime("%-m/%-d/%Y")
  end

  def format_case_details(hearing)
    file_number = ["(", hearing.veteran_file_number, ")"].join
    [hearing.veteran_first_name, hearing.veteran_last_name, file_number].join(" ")
  end

  def serialize_hearing(hearing)
    {
      docketNumber: hearing.docket_number,
      caseDetails: format_case_details(hearing),
      hearingType: hearing.class.name
    }
  end
end
