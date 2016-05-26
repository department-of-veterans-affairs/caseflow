# frozen_string_literal: true

class MismatchReport < Report
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
