# frozen_string_literal: true

module ParserHelper
  # Checking for nonrating_issue_category is "Disposition" and processing such issues.
  def process_nonrating_issue_category(payload_json)
    payload_json[:request_issues].each do |issue|
      next unless issue[:nonrating_issue_category] == "Disposition"

      issue[:nonrating_issue_category] = "Unknown Issue Category"
    end
  end

  # Generic/universal methods
  # rubocop:disable Rails/TimeZone
  def convert_milliseconds_to_datetime(milliseconds)
    milliseconds.nil? ? nil : Time.at(milliseconds.to_i / 1000).to_datetime
  end
  # rubocop:enable Rails/TimeZone

  # convert logical date int to date
  def logical_date_converter(logical_date_int)
    return nil if logical_date_int.nil? || logical_date_int.to_i.days == 0

    base_date = Date.new(1970, 1, 1)
    converted_date = base_date + logical_date_int.to_i.days
    converted_date
  end
end
