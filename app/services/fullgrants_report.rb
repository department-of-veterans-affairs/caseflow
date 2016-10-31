class FullgrantsReport < Report
  def self.output_filename
    "fullgrants"
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
    VACOLS::Case.fullgrants_for_ep(7.days.ago)
  end

  def load_record(case_record)
    AppealRepository.create_appeal(case_record)
  end

  def include_record?(_appeal)
    true
  end

  def cleanup_record(_appeal)
  end
end
