class SeamReport < Report
  def self.output_filename
    "seam"
  end

  def self.table_columns
    [
      "BFKEY",
      "TYPE",
      "FILE TYPE",
      "AOJ",
      "DOCS IN VBMS",
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
      vbms_docs(appeal),
      appeal.nod_date,
      appeal.certification_date,
      bool_str(appeal.hearing_pending?),
      appeal.vbms_id,
      bool_str(appeal.disposition == "Merged Appeal")
    ]
  end

  def self.vbms_docs(appeal)
    docs = []

    ["NOD", "Form 9", "SOC", "SSOC"].each do |type|
      docs << type if appeal.documents_with_type(type).length.nonzero?
    end

    docs.join(", ")
  end

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

  def find_records
    VACOLS::Case.joins(:folder, :correspondent).where(%{

      bf41stat < ?
      -- We ignore super recent cases, as there may be work in progress.

      AND bfmpro = ?
      -- We're only thinking about cases that have not yet been received by
      -- BVA, so we limit our search to cases in ADV (Advance) status.

      AND (folder.tivbms IS NULL OR
           folder.tivbms NOT IN (?))
      -- We also want things *absolutely* marked as a paper case, so let's
      -- ignore anything that's marked as being worked in the efolder.

      AND bfregoff NOT IN (?)
      -- Finally, we'll ignore any ROs we know to be paper only, even
      -- if the appellant has an eFolder.

    }, 2.weeks.ago, "ADV", %w(Y 1 0), PAPER_ONLY_OFFICES)
  end

  def load_record(case_record)
    AppealRepository.build_appeal(case_record)
  end

  def include_record?(appeal)
    ["NOD", "Form 9", "SOC", "SSOC"].any? { |t| appeal.documents_with_type(t).length.nonzero? }
  end

  def cleanup_record(appeal)
    appeal.clear_documents!
  end
end
