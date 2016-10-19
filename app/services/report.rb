require "csv"
require "parallel"

class Report
  def self.table_row(record)
    table_columns.map { |k| record.send(k) }
  end

  def self.bool_str(val)
    "Y" if val
    "N"
  end

  def self.mismatched_docs(appeal)
    mismatched = []

    mismatched << "NOD" unless appeal.nod_match?
    mismatched << "SOC" unless appeal.soc_match?
    mismatched << "Form 9" unless appeal.form9_match?
    mismatched << "SSOC" unless appeal.ssoc_all_match?

    mismatched.join(", ")
  end

  def run!
    filename = "reports/#{self.class.output_filename}_#{Time.zone.today.strftime('%Y-%m-%d')}.csv"

    CSV.open(filename, "wb") do |csv|
      csv << self.class.table_columns
      rows = find_records

      Parallel.each(rows, in_threads: 4, progress: "Loading records") do |row|
        record = nil
        begin
          record = load_record row
          csv << self.class.table_row(record) if include_record? record
        rescue => e
          Rails.logger.error <<-EOS.strip_heredoc
            event=report.case.exception
            bfkey=#{row.bfkey}
            message=#{e.message}
            traceback=#{e.backtrace}
          EOS
        end
        cleanup_record record unless record.nil?
      end
    end
  end
end
