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
      "CASEFLOW",
      "HAS HEARING PENDING",
      "CORLID",
      "IS MERGED",
      "NOD DATE ALTERNATIVES",
      "NOD LABEL ALTERNATIVES",
      "FORM 9 DATE ALTERNATIVES",
      "FORM 9 LABEL ALTERNATIVES"
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
      bool_str(appeal.case_record.bfdcertool),
      bool_str(appeal.hearing_pending),
      appeal.vbms_id,
      bool_str(appeal.merged),
      nod_date_alternatives(appeal),
      nod_label_alternatives(appeal),
      form9_date_alternatives(appeal),
      form9_label_alternatives(appeal)
    ]
  end

  def self.mismatched_docs(appeal)
    mismatched = []

    mismatched << "NOD" unless appeal.nod_match?
    mismatched << "SOC" unless appeal.soc_match?
    mismatched << "Form 9" unless appeal.form9_match?
    mismatched << "SSOC" unless appeal.ssoc_all_match?

    mismatched.join(", ")
  end

  ALTERNATIVE_AGE_THRESHOLD = 3 # days

  ALTERNATIVE_DOC_TYPES = {
    34  => "Correspondence",
    115 => "VA 21-4138 Statement In Support of Claim",
    475 => "Third Party Correspondence"
  }.freeze

  def self.nod_date_alternatives(appeal)
    return "" if appeal.nod_match?

    # Do we have an NOD from within 3 days of what VACOLS shows?
    appeal.documents_with_type(:nod)
          .map(&:received_at)
          .select { |date| (appeal.nod_date.to_date - date.to_date).abs <= ALTERNATIVE_AGE_THRESHOLD }
          .join(", ")
  end

  def self.form9_date_alternatives(appeal)
    return "" if appeal.form9_match?

    # Do we have a Form 9 from within 3 days of what VACOLS shows?
    appeal.documents_with_type(:form9)
          .map(&:received_at)
          .select { |date| (appeal.form9_date.to_date - date.to_date).abs <= ALTERNATIVE_AGE_THRESHOLD }
          .join(", ")
  end

  def self.nod_label_alternatives(appeal)
    return "" if appeal.nod_match?

    # Do we have a document on the NOD date marked as something else?
    appeal.documents
          .map do |doc|
            ALTERNATIVE_DOC_TYPES[doc.vbms_doc_type.to_i] if
              appeal.nod_date.to_date == doc.received_at.to_date &&
              ALTERNATIVE_DOC_TYPES.include?(doc.vbms_doc_type.try(:to_i))
          end
          .compact
          .join(", ")
  end

  def self.form9_label_alternatives(appeal)
    return "" if appeal.form9_match?

    # Do we have a document on the Form 9 date marked as something else?
    appeal.documents
          .map do |doc|
            ALTERNATIVE_DOC_TYPES[doc.vbms_doc_type.to_i] if
              appeal.form9_date.to_date == doc.received_at.to_date &&
              ALTERNATIVE_DOC_TYPES.include?(doc.vbms_doc_type.try(:to_i))
          end
          .compact
          .join(", ")
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

      AND folder.tivbms IN (?)
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
