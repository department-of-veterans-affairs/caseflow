class FullGrantsReport < Report
  def self.output_filename
    "full_grants"
  end

  def self.table_columns
    [
      "Appeal Id",
      "Name",
      "RO",
      "Decision Date",
      "Disposition",
      "Representative"
    ]
  end

  def self.table_row(appeal)
    [
      appeal.case_record.bfkey,
      "#{appeal.veteran_first_name} #{appeal.veteran_last_name}",
      appeal.regional_office_name,
      appeal.decision_date,
      appeal.disposition,
      appeal.representative
    ]
  end

  def find_records
    VACOLS::Case.amc_full_grants(decided_after: 7.days.ago)
  end

  def load_record(case_record)
    AppealRepository.build_appeal(case_record)
  end

  def include_record?(_appeal)
    true
  end

  def cleanup_record(_appeal)
  end
end
