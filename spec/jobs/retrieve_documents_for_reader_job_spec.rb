require "rails_helper"
require "faker"

describe RetrieveAppealsDocumentsForReaderJob do
  before(:all) do
    S3Service = Caseflow::Fakes::S3Service
    User.case_assignment_repository = Fakes::CaseAssignmentRepository
  end

  context ".perform" do
    let!(:reader_user) do
      Generators::User.create(roles: ["Reader"])
    end

    let!(:reader_user_w_many_roles) do
      Generators::User.create(roles: ["Something else", "Reader", Faker::Zelda.character])
    end

    let!(:non_reader_user) do
      Generators::User.create(roles: ["Something else"])
    end

    let!(:expected_doc1) do
      Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago)
    end

    let!(:expected_doc2) do
      Generators::Document.build(type: "BVA Decision", received_at: 10.days.ago)
    end

    let!(:appeal_with_doc1) do
      Generators::Appeal.create(
        vbms_id: expected_doc1.vbms_document_id,
        vacols_record: { template: :remand_decided, decision_date: 7.days.ago }
      )
    end

    let!(:appeal_with_doc2) do
      Generators::Appeal.create(
        vbms_id: expected_doc2.vbms_document_id,
        vacols_record: { template: :remand_decided, decision_date: 7.days.ago }
      )
    end

    let!(:unexpected_document) do
      Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago)
    end

    let!(:appeal_with_doc_for_non_reader) do
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
      # Reset S3 mock files
      S3Service.files = nil

      # Fail test if Mock is called for non-reader user
      expect(Fakes::CaseAssignmentRepository).not_to receive(:load_from_vacols).with(non_reader_user.css_id)
      dont_expect_calls_for_appeal(appeal_with_doc_for_non_reader, unexpected_document)
    end

    context "when a limit is not provided" do
      before do
        expect_all_calls_for_user(reader_user, appeal_with_doc1, expected_doc1, doc1_expected_content)
        expect_all_calls_for_user(reader_user_w_many_roles, appeal_with_doc2, expected_doc2, doc2_expected_content)
      end

      it "retrieves the appeal documents for all reader users" do
        RetrieveAppealsDocumentsForReaderJob.perform_now

        # Validate that the decision content is cached in S3 mock
        expect(S3Service.files[expected_doc1.vbms_document_id]).to eq(doc1_expected_content)
        expect(S3Service.files[expected_doc2.vbms_document_id]).to eq(doc2_expected_content)
        expect(S3Service.files[unexpected_document.vbms_document_id]).to be_nil
      end
    end

    context "when a limit is provided" do
      let!(:new_doc) do
        Generators::Document.build(type: Faker::Shakespeare.as_you_like_it_quote, received_at: 6.days.ago)
      end

      let!(:new_doc_expected_content) do
        Faker::Shakespeare.king_richard_iii_quote
      end

      before do
        # appeal_with_doc1 will have 2 docs associated with it
        expect(Fakes::CaseAssignmentRepository).to receive(:load_from_vacols).with(reader_user.css_id)
          .and_return([appeal_with_doc1]).once

        expect(VBMSService).to receive(:fetch_documents_for).with(appeal_with_doc1)
          .and_return([expected_doc1, new_doc]).once

        expect_calls_for_doc(expected_doc1, doc1_expected_content)
        expect_calls_for_doc(new_doc, new_doc_expected_content)

        expect(Fakes::CaseAssignmentRepository).to receive(:load_from_vacols).with(reader_user_w_many_roles.css_id)
          .and_return([appeal_with_doc2]).once
        dont_expect_calls_for_appeal(appeal_with_doc2, expected_doc2)
      end

      it "stops if limit is reached after finishing current case" do
        RetrieveAppealsDocumentsForReaderJob.perform_now(limit: 1)

        expect(S3Service.files[expected_doc1.vbms_document_id]).to eq(doc1_expected_content)
        expect(S3Service.files[new_doc.vbms_document_id]).to eq(new_doc_expected_content)
        expect(S3Service.files[expected_doc2.vbms_document_id]).to be_nil
        expect(S3Service.files[unexpected_document.vbms_document_id]).to be_nil
      end
    end

    context "VBMS exception is thrown" do
      before do
        expect(Fakes::CaseAssignmentRepository).to receive(:load_from_vacols).with(reader_user.css_id)
          .and_return([appeal_with_doc1]).once
        expect(S3Service).to receive(:exists?).with(expected_doc1.vbms_document_id).and_return(false).once
        expect(VBMSService).to receive(:fetch_documents_for).with(appeal_with_doc1).and_return([expected_doc1])
          .once
        expect(VBMSService).to receive(:fetch_document_file).with(expected_doc1)
          .and_raise(VBMS::ClientError.new("<faultstring>Womp Womp.</faultstring>"))
          .once

        expect_all_calls_for_user(reader_user_w_many_roles, appeal_with_doc2, expected_doc2, doc2_expected_content)
      end

      it "catches the exception and continues to the next document" do
        RetrieveAppealsDocumentsForReaderJob.perform_now

        expect(S3Service.files[expected_doc1.vbms_document_id]).to be_nil
        expect(S3Service.files[expected_doc2.vbms_document_id]).to eq(doc2_expected_content)
        expect(S3Service.files[unexpected_document.vbms_document_id]).to be_nil
      end
    end
  end

  def dont_expect_calls_for_appeal(appeal, doc)
    expect(VBMSService).not_to receive(:fetch_documents_for).with(appeal)
    expect(S3Service).not_to receive(:exists?).with(doc.vbms_document_id)
    expect(VBMSService).not_to receive(:fetch_document_file).with(doc)
  end

  def expect_all_calls_for_user(user, appeal, doc, content)
    expect(Fakes::CaseAssignmentRepository).to receive(:load_from_vacols).with(user.css_id)
      .and_return([appeal]).once
    expect_calls_for_appeal(appeal, doc, content)
  end

  def expect_calls_for_appeal(appeal, doc, content)
    expect(VBMSService).to receive(:fetch_documents_for).with(appeal).and_return([doc]).once
    expect_calls_for_doc(doc, content)
  end

  def expect_calls_for_doc(doc, content)
    expect(S3Service).to receive(:exists?).with(doc.vbms_document_id).and_return(false).once
    expect(VBMSService).to receive(:fetch_document_file).with(doc).and_return(content).once
  end
end
