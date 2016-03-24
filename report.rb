require 'csv'
require 'parallel'


PAPER_ONLY_OFFICES = [
  # General Councel
  "RO89",

  # Education Centers
  "RO91", "RO92", "RO93", "RO94",

  # Pension
  "RO80", "RO81", "RO82", "RO83",

  # VHA CO
  "RO99"
].freeze

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
    mismatched_fields.map {|_, _, field_name| field_name }.join(", ")
  end

  def run!
    CSV.open("output.csv", "wb") do |csv|
      csv << self.class.spreadsheet_columns
      rows = find

      Parallel.each(rows, in_threads: 4, progress: "Loading Records") do |row|
      # rows.each do |row|
        record = nil
        begin
          record = load_record row
          csv << self.class.spreadsheet_values(record) unless !include_record? record
        rescue => e
          Rails.logger.error "event=report.case.exception bfkey=#{row.bfkey} message=#{e.message} traceback=#{e.backtrace}"
        end
        cleanup record unless record.nil?
      end
    end
  end
end

class MismatchReport < Report
  def self.spreadsheet_columns
    [
      "BFKEY",
      "TYPE",
      "FILE TYPE",
      "AOJ",
      "NOD DATE",
      "CERT DATE",
      "HAS HEARING PENDING",
      "CORLID",
      "IS MERGED"
    ]
  end

  # vacols_case.bfkey,
  # TYPE_ACTION[vacols_case.bfac],
  # vacols_case.folder.file_type,
  # vacols_case.regional_office_full,
  # vacols_case.bfdnod,
  # vacols_case.bf41stat,
  # Caseflow::Reports.hearing_pending(vacols_case),
  #
  # vacols_case.bfcorlid,
  # Caseflow::Reports.bool_cell(vacols_case.merged?),

  def self.spreadsheet_values(appeal)
    [
      appeal.case_record.bfkey,
      appeal.action_name,
      appeal.file_type,
      appeal.regional_office_name,
      appeal.nod_date,
      appeal.certification_date,
      spreadsheet_bool(appeal.hearing_pending),
      appeal.vbms_id,
      spreadsheet_bool(appeal.merged)
    ]
  end

  def cleanup(appeal)
    # Clear the list of eFolder documents on the case, otherwise the memory of
    # this script grows over time.
    appeal.clear_documents! unless appeal.nil?
  end

  def find
    Records::Case.joins(:folder, :correspondent).where(%{

      bf41stat < ?
      -- We ignore super recent cases, since there may be race conditions
      -- with the case getting to the scanning vendor and documents reaching
      -- the efolder.

      AND bfmpro = ?
      -- We're only thinking about cases which have been certified (advanced)
      -- to the BVA; so let's filter on anything that's in ADV.

      AND (folder.tivbms IS NULL OR
           folder.tivbms NOT IN (?))
      -- We also want things that *absolutely* marked as a paper case, so lets
      -- ignore anything that's marked as being worked in the efolder.

      AND bfregoff NOT IN (?)
      -- Finally, we'll ignore any ROs we know to be paper only, even
      -- if the appellant has an eFolder.

    }, 2.weeks.ago, "ADV", %w(Y 1 0), PAPER_ONLY_OFFICES)
  end

  def load_record(case_record)
    AppealRepository.create_appeal(case_record)
  end

  def include_record?(appeal)
    appeal.any_appeals_document?
  end
end

report = MismatchReport.new
report.run!
