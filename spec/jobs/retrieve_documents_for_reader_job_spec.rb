require "rails_helper"
require "faker"

describe RetrieveDocumentsForReaderJob do
  before(:all) do
    S3Service = Caseflow::Fakes::S3Service
    User.appeal_repository = Fakes::AppealRepository
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
      expect(Fakes::AppealRepository).not_to receive(:load_user_case_assignments_from_vacols)
        .with(non_reader_user.css_id)
      dont_expect_calls_for_appeal(appeal_with_doc_for_non_reader, unexpected_document)

      # Expect all tests to call Slack service at the end
      expect_any_instance_of(SlackService).to receive(:send_notification).with(expected_slack_msg).once
    end

    context "when a limit is not provided" do
      let!(:expected_slack_msg) do
        "RetrieveDocumentsForReaderJob successfully retrieved 2 documents for 2 appeals and 0 document(s) failed.\n" \
          "Failed to retrieve documents for 0 appeal(s)."
      end

      it "retrieves the appeal documents for all reader users" do
        expect_all_calls_for_user(reader_user, appeal_with_doc1, expected_doc1, doc1_expected_content)
        expect_all_calls_for_user(reader_user_w_many_roles, appeal_with_doc2, expected_doc2, doc2_expected_content)

        RetrieveDocumentsForReaderJob.perform_now

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

      let!(:expected_slack_msg) do
        "RetrieveDocumentsForReaderJob successfully retrieved 2 documents for 1 appeals and 0 document(s) failed.\n" \
        "Failed to retrieve documents for 0 appeal(s)."
      end

      it "stops if limit is reached after finishing current case" do
        # appeal_with_doc1 will have 2 docs associated with it
        expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
          .with(reader_user.css_id)
          .and_return([appeal_with_doc1]).once

        expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc1, anything)
          .and_return([expected_doc1, new_doc]).once

        expect_calls_for_doc(expected_doc1, doc1_expected_content)
        expect_calls_for_doc(new_doc, new_doc_expected_content)

        expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
          .with(reader_user_w_many_roles.css_id)
          .and_return([appeal_with_doc2]).once

        dont_expect_calls_for_appeal(appeal_with_doc2, expected_doc2)

        RetrieveDocumentsForReaderJob.perform_now("limit" => 1)

        expect(S3Service.files[expected_doc1.vbms_document_id]).to eq(doc1_expected_content)
        expect(S3Service.files[new_doc.vbms_document_id]).to eq(new_doc_expected_content)
        expect(S3Service.files[expected_doc2.vbms_document_id]).to be_nil
        expect(S3Service.files[unexpected_document.vbms_document_id]).to be_nil
      end
    end

    context "when VBMS exception is thrown" do
      context "when trying to fetch an appeal" do
        let!(:expected_slack_msg) do
          "RetrieveDocumentsForReaderJob successfully retrieved 1 documents for 1 appeals and 0 document(s) failed.\n" \
          "Failed to retrieve documents for 1 appeal(s)."
        end

        it "catches the exception when thrown by fetch_documents_for and continues to the next appeal" do
          expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
            .with(reader_user.css_id)
            .and_return([appeal_with_doc1]).once

          expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc1, anything)
            .and_raise(VBMS::ClientError.new("<faultstring>Womp Womp.</faultstring>")).once

          expect_all_calls_for_user(reader_user_w_many_roles, appeal_with_doc2, expected_doc2, doc2_expected_content)

          RetrieveDocumentsForReaderJob.perform_now

          expect(S3Service.files[expected_doc1.vbms_document_id]).to be_nil
          expect(S3Service.files[expected_doc2.vbms_document_id]).to eq(doc2_expected_content)
          expect(S3Service.files[unexpected_document.vbms_document_id]).to be_nil
        end
      end

      context "when trying to fetch an appeal" do
        let!(:expected_slack_msg) do
          "RetrieveDocumentsForReaderJob successfully retrieved 1 documents for 2 appeals and 1 document(s) failed.\n" \
          "Failed to retrieve documents for 0 appeal(s)."
        end

        it "catches the exception when thrown by fetch_content and continues to the next document" do
          expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
            .with(reader_user.css_id)
            .and_return([appeal_with_doc1]).once
          expect(S3Service).to receive(:exists?).with(expected_doc1.vbms_document_id).and_return(false).once
          expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc1, anything)
            .and_return([expected_doc1]).once
          expect(EFolderService).to receive(:fetch_document_file).with(expected_doc1)
            .and_raise(VBMS::ClientError.new("<faultstring>Womp Womp.</faultstring>"))
            .once

          expect_all_calls_for_user(reader_user_w_many_roles, appeal_with_doc2, expected_doc2, doc2_expected_content)

          RetrieveDocumentsForReaderJob.perform_now

          expect(S3Service.files[expected_doc1.vbms_document_id]).to be_nil
          expect(S3Service.files[expected_doc2.vbms_document_id]).to eq(doc2_expected_content)
          expect(S3Service.files[unexpected_document.vbms_document_id]).to be_nil
        end
      end
    end

    context "when HTTP Timeout occurs" do
      let!(:expected_slack_msg) do
        "RetrieveDocumentsForReaderJob successfully retrieved 0 documents for 0 appeals and 0 document(s) failed.\n" \
        "Failed to retrieve documents for 2 appeal(s)."
      end

      it "catches the exception and continues to the next appeal" do
        expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
          .with(reader_user.css_id)
          .and_return([appeal_with_doc1]).once
        expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
          .with(reader_user_w_many_roles.css_id)
          .and_return([appeal_with_doc2]).once

        expect(VBMSService).to receive(:fetch_documents_for).with(any_args)
          .and_raise(HTTPClient::KeepAliveDisconnected.new("You lose.")).exactly(2).times

        RetrieveDocumentsForReaderJob.perform_now

        expect(S3Service.files).to be_nil
      end
    end

    context "when consecutive errors occur" do
      let!(:expected_slack_msg) do
        "RetrieveDocumentsForReaderJob successfully retrieved 1 documents for 1 appeals and 0 document(s) failed.\n" \
        "Failed to retrieve documents for 6 appeal(s).\nJob stopped after 6 failures"
      end

      it "stops executing after 5 errors" do
        appeals_that_fail = [appeal_with_doc1] + (0..4).map { create_doc_and_appeal }
        reader_user_appeals = [appeal_with_doc2] + appeals_that_fail

        expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
          .with(reader_user.css_id)
          .and_return(reader_user_appeals).once

        expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
          .with(reader_user_w_many_roles.css_id)
          .and_return(nil).once

        # Checks that counter is reset by having one call succeed in between failures
        expect_calls_for_appeal(appeal_with_doc2, expected_doc2, doc2_expected_content)

        appeals_that_fail.each do |appeal|
          expect(Fakes::VBMSService).to receive(:fetch_documents_for).with(appeal, instance_of(User))
            .and_raise(HTTPClient::KeepAliveDisconnected.new("You lose."))
            .once
        end

        RetrieveDocumentsForReaderJob.perform_now

        expect(S3Service.files.length).to eq(1)
        expect(S3Service.files[expected_doc2.vbms_document_id]).to eq(doc2_expected_content)
      end
    end

    context "when efolder is enabled" do
      before do
        FeatureToggle.enable!(:efolder_docs_api)
        RequestStore.store[:application] = "reader"
      end

      after { FeatureToggle.disable!(:efolder_docs_api) }

      let!(:expected_slack_msg) do
        "RetrieveDocumentsForReaderJob successfully retrieved 0 documents for 2 appeals and 0 document(s) failed.\n" \
          "Failed to retrieve documents for 0 appeal(s)."
      end

      it "does not fetch content" do
        expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
          .with(reader_user.css_id)
          .and_return([appeal_with_doc1]).once

        expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc1, reader_user)
          .and_return([expected_doc1]).once

        expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
          .with(reader_user_w_many_roles.css_id)
          .and_return([appeal_with_doc2]).once

        expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc2, reader_user_w_many_roles)
          .and_return([expected_doc2]).once

        RetrieveDocumentsForReaderJob.perform_now
        expect(S3Service.files).to be_nil
      end
    end

    context "when files exist in S3" do
      let!(:expected_slack_msg) do
        "RetrieveDocumentsForReaderJob successfully retrieved 0 documents for 2 appeals and 0 document(s) failed.\n" \
          "Failed to retrieve documents for 0 appeal(s)."
      end

      it "does not fetch content" do
        allow(S3Service).to receive(:exists?).with(any_args).and_return(true)

        expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols).with(reader_user.css_id)
          .and_return([appeal_with_doc1]).once

        expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc1, reader_user)
          .and_return([expected_doc1]).once

        expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
          .with(reader_user_w_many_roles.css_id)
          .and_return([appeal_with_doc2]).once

        expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc2, reader_user_w_many_roles)
          .and_return([expected_doc2]).once

        RetrieveDocumentsForReaderJob.perform_now
        expect(S3Service.files).to be_nil
      end
    end
  end

  def dont_expect_calls_for_appeal(appeal, doc)
    expect(EFolderService).not_to receive(:fetch_documents_for).with(appeal, anything)
    expect(S3Service).not_to receive(:exists?).with(doc.vbms_document_id)
    expect(EFolderService).not_to receive(:fetch_document_file).with(doc)
  end

  def expect_all_calls_for_user(user, appeal, doc, content)
    expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
      .with(user.css_id)
      .and_return([appeal]).once
    expect_calls_for_appeal(appeal, doc, content)
  end

  def expect_calls_for_appeal(appeal, doc, content)
    expect(EFolderService).to receive(:fetch_documents_for).with(appeal, anything).and_return([doc]).once
    expect_calls_for_doc(doc, content)
  end

  def expect_calls_for_doc(doc, content)
    expect(S3Service).to receive(:exists?).with(doc.vbms_document_id).and_return(false).once
    expect(EFolderService).to receive(:fetch_document_file).with(doc).and_return(content).once
  end

  def create_doc_and_appeal
    doc = Generators::Document.build(type: "BVA Decision", received_at: 10.days.ago)
    Generators::Appeal.create(
      vbms_id: doc.vbms_document_id,
      vacols_record: { template: :remand_decided, decision_date: 7.days.ago }
    )
  end
end
