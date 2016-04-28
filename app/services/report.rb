# frozen_string_literal: true

require "csv"
require "parallel"

class Report
  def self.spreadsheet_values(row)
    spreadsheet_columns.map { |k| row.send(k) }
  end

  def self.spreadsheet_bool(val)
    "Y" if val
    "N"
  end

  def self.mismatched_dates(c)
    mismatched_fields = RELEVANT_FIELDS.select do |vacols_field, vbms_field|
      c.send(vacols_field) != c.send(vbms_field)
    end
    mismatched_fields.map { |_, _, field_name| field_name }.join(", ")
  end

  def run!
    CSV.open("output.csv", "wb") do |csv|
      csv << self.class.spreadsheet_columns
      rows = find

      Parallel.each(rows, in_threads: 4, progress: "Loading Records") do |row|
        record = nil
        begin
          record = load_record row
          csv << self.class.spreadsheet_values(record) if include_record? record
        rescue => e
          Rails.logger.error %(event=report.case.exception
bfkey=#{row.bfkey}
message=#{e.message}
traceback=#{e.backtrace})
        end
        cleanup record unless record.nil?
      end
    end
  end
end
