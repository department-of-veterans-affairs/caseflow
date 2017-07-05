require "rails_helper"
require "faker"

describe RetrieveAppealsDocumentsForReaderJob do
  context ".perform" do
    let!(:reader_user) do
      Generators::User.create(roles: ["Reader"])
    end

    let!(:reader_user_with_multiple_roles) do
      Generators::User.create(roles: ["Something else", "Reader", Faker::Zelda.character])
    end

    let!(:non_reader_user) do
      Generators::User.create(roles: ["Something else"])
    end

    let!(:expected_document_1) do
      Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago)
    end

    let!(:expected_document_2) do
      Generators::Document.build(type: "BVA Decision", received_at: 10.days.ago)
    end

    let!(:appeal_with_document) do
      Generators::Appeal.create(
        vbms_id: expected_document_1.vbms_document_id,
        vacols_record: { template: :remand_decided, decision_date: 7.days.ago }
      )
    end

    let!(:another_appeal_with_document) do
      Generators::Appeal.create(
        vbms_id: expected_document_2.vbms_document_id,
        vacols_record: { template: :remand_decided, decision_date: 7.days.ago }
      )
    end

    let!(:unexpected_document) do
      Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago)
    end

    let!(:appeal_with_document_for_non_reader) do
      Generators::Appeal.create(
        vbms_id: unexpected_document.vbms_document_id,
        vacols_record: { template: :remand_decided, decision_date: 7.days.ago }
      )
    end

    let!(:doc1_expected_content) do
      Faker::HarryPotter.quote
    end

    let!(:doc2_expected_content) do
      Faker::Pokemon.name
    end

    before do
      User.case_assignment_repository = Fakes::CaseAssignmentRepository

      # Expect calls to service for all users with Reader roles
      expect(Fakes::CaseAssignmentRepository).to receive(:load_from_vacols).with(reader_user.css_id)
        .and_return([appeal_with_document]).once
      expect(Fakes::CaseAssignmentRepository).to receive(:load_from_vacols).with(reader_user_with_multiple_roles.css_id)
        .and_return([another_appeal_with_document]).once

      # Expect calls to VBMS service to retrieve content from VBMS
      expect(VBMSService).to receive(:fetch_documents_for).with(appeal_with_document).and_return([expected_document_1])
        .once
      expect(VBMSService).to receive(:fetch_document_file).with(expected_document_1).and_return(doc1_expected_content)
        .once
      expect(VBMSService).to receive(:fetch_documents_for).with(another_appeal_with_document)
        .and_return([expected_document_2]).once
      expect(VBMSService).to receive(:fetch_document_file).with(expected_document_2).and_return(doc2_expected_content)
        .once
    end

    it "retrieves the appeal documents for reader users" do
      RetrieveAppealsDocumentsForReaderJob.perform_now

      # Validate that the decision content is cached in S3 mock
      expect(S3Service.files[expected_document_1.vbms_document_id]).to eq(doc1_expected_content)
      expect(S3Service.files[expected_document_2.vbms_document_id]).to eq(doc2_expected_content)
      expect(S3Service.files[unexpected_document.vbms_document_id]).to be_nil
    end
  end
end
