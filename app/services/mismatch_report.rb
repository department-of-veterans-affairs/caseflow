class MismatchReport < Report
  def self.output_filename
    "mismatch"
  end

  def self.table_columns
    [
      "BFKEY",
      "TYPE",
      "FILE TYPE",
      "AOJ",
      "MISMATCHED_DOCS",
      "NOD DATE",
      "CERT DATE",
      "HAS HEARING PENDING",
      "CORLID",
      "IS MERGED"
    ]
  end

  def self.table_row(appeal)
    [
      appeal.case_record.bfkey,
      appeal.type,
      appeal.file_type,
      appeal.regional_office_name,
      mismatched_docs(appeal),
      appeal.nod_date,
      appeal.certification_date,
      bool_str(appeal.hearing_pending),
      appeal.vbms_id,
      bool_str(appeal.merged)
    ]
  end

  def find_records
    VACOLS::Case.joins(:folder, :correspondent).where(%{

      bf41stat < ?
      -- We ignore super recent cases, since there may be race conditions
      -- with the case getting to the scanning vendor and documents reaching
      -- the efolder.

      AND bfmpro = ?
      -- We're only thinking about cases that have not yet been received by
      -- BVA, so we limit our search to cases in ADV (Advance) status.

      AND folder.tivbms IN ?
      -- Only efolder cases need apply

    }, 2.weeks.ago, "ADV", %w(Y 1 0))
  end

  def load_record(case_record)
    AppealRepository.create_appeal(case_record)
  end

  def include_record?(appeal)
    !appeal.documents_match?
  end

  def cleanup_record(appeal)
    appeal.clear_documents!
  end
end
