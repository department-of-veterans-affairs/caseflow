# frozen_string_literal: true

class CorrespondenceDocument < CaseflowRecord
  belongs_to :correspondence
  belongs_to :vbms_document_type

  def pdf_name
    "#{uuid}.pdf"
  end

  # :reek:UtilityFunction
  # :nocov:
  def pdf_location
    File.join(Rails.root, "lib", "pdfs", "KnockKnockJokes.pdf")
  end
  # :nocov:

  # contentName, providerData: {contentSource:, documentTypeId:, dateVaReceivedDocument:} are required fields
  def claim_evidence_upload_hash
    {
      contentName: pdf_name,
      providerData: {
        contentSource: "VISTA",
        claimantFirstName: correspondence.veteran.first_name,
        claimantLastName: correspondence.veteran.last_name,
        claimantParticipantId: correspondence.veteran.participant_id,
        claimantSsn: correspondence.veteran.ssn,
        documentTypeId: vbms_document_type_id,
        dateVaReceivedDocument: correspondence.va_date_of_receipt.strftime("%Y-%m-%d"),
        actionable: true
      }
    }
  end
end
