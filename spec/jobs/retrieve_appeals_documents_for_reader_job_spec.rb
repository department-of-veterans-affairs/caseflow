require "rails_helper"
require "byebug"

describe RetrieveAppealsDocumentsForReaderJob do
  let!(:reader_user) do
    Generators::User.create(roles: ["Reader"])
  end

  let!(:expected_document) do
    Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago)
  end

  let!(:appeal_with_document) do
    Generators::Appeal.create(
      vbms_id: expected_document.vbms_document_id,
      vacols_record: { template: :remand_decided, decision_date: 7.days.ago }
    )
  end

  before do
    User.case_assignment_repository = Fakes::CaseAssignmentRepository
    Fakes::CaseAssignmentRepository.appeal_records = [appeal_with_document]
    expect(VBMSService).to receive(:fetch_documents_for).and_return([expected_document])
    expect(VBMSService).to receive(:fetch_document_file).and_return("This is my expected content")
  end

  context ".perform" do
    it "retrieves the appeal documents" do
      RetrieveAppealsDocumentsForReaderJob.perform_now

      # Validate that the decision content is cached in S3
      expect(S3Service.files[expected_document.vbms_document_id]).to eq("This is my expected content")
    end
  end
end
