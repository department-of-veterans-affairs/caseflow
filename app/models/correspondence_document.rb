# frozen_string_literal: true

class CorrespondenceDocument < CaseflowRecord
  belongs_to :correspondence
  belongs_to :vbms_document_type

  S3_BUCKET_NAME = "documents"

  def pdf_name
    "#{uuid}.pdf"
  end

  def s3_location
    "#{S3_BUCKET_NAME}/#{uuid}"
  end

  # :reek:UtilityFunction
  def output_location
    File.join(Rails.root, "tmp", "pdfs", pdf_name)
  end

  def pdf_location
    S3Service.fetch_file(s3_location, output_location)
  end

  def claim_evidence_upload_json
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
    }.to_json
  end
end
