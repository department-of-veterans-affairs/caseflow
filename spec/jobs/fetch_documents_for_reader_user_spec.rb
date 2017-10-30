require "rails_helper"
require "faker"

describe FetchDocumentsForReaderUserJob do
  before(:all) do
    User.appeal_repository = Fakes::AppealRepository
    S3Service = Caseflow::Fakes::S3Service
  end

  context ".perform" do
    let!(:user_with_reader_role) do
      Generators::User.create(roles: ["Reader"])
    end

    let!(:reader_user) do
      Generators::ReaderUser.create(user_id: user_with_reader_role.id)
    end

    let!(:user_w_reader_and_many_roles) do
      Generators::User.create(roles: ["Something else", "Reader", Faker::Zelda.character])
    end

    let!(:reader_user_w_many_roles) do
      Generators::ReaderUser.create(user_id: user_w_reader_and_many_roles.id)
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

    let!(:service_manifest_vbms_fetched_at) do
      Time.zone.local(1989, "nov", 23, 8, 2, 55).strftime("%D %l:%M%P %Z")
    end

    let!(:service_manifest_vva_fetched_at) do
      Time.zone.local(1989, "dec", 13, 20, 15, 1).strftime("%D %l:%M%P %Z")
    end

    let!(:doc_struct) do
      {
        manifest_vbms_fetched_at: service_manifest_vbms_fetched_at,
        manifest_vva_fetched_at: service_manifest_vva_fetched_at
      }
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

    context "when a reader user with 1 appeal is provided" do
      let!(:expected_slack_msg) do
        "FetchDocumentsForReaderUserJob (user_id: #{current_user_id}) SUCCESS. " \
        "It retrieved 1 documents for 1 / 1 appeals and 0 document(s) failed.\n" \
      end

      context "the user has one reader role" do
        let!(:current_user_id) do
          reader_user.user.id
        end
        it "retrieves the appeal document" do
          expect_all_calls_for_user(reader_user.user, appeal_with_doc1, expected_doc1, doc1_expected_content)
          FetchDocumentsForReaderUserJob.perform_now(reader_user)

          expect(S3Service.files[expected_doc1.vbms_document_id]).to eq(doc1_expected_content)
          expect(S3Service.files[unexpected_document.vbms_document_id]).to be_nil
        end
      end

      context "the user has many roles including a reader role" do
        let!(:current_user_id) do
          reader_user_w_many_roles.user.id
        end
        it "retrieves the appeal document" do
          expect_all_calls_for_user(
            reader_user_w_many_roles.user,
            appeal_with_doc2,
            expected_doc2,
            doc2_expected_content
          )
          FetchDocumentsForReaderUserJob.perform_now(reader_user_w_many_roles)

          expect(S3Service.files[expected_doc2.vbms_document_id]).to eq(doc2_expected_content)
          expect(S3Service.files[unexpected_document.vbms_document_id]).to be_nil
        end
      end
    end

    context "when VBMS exception is thrown" do
      context "on the first appeal" do
        let!(:expected_slack_msg) do
          "FetchDocumentsForReaderUserJob (user_id: #{current_user_id}) ERROR. " \
            "It retrieved 0 documents for 0 / 2 appeals and 0 document(s) failed.\n"
        end
        let!(:current_user_id) do
          reader_user.user.id
        end

        it "returns an ERROR log with status when a VBMS client error occurs" do
          expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
            .with(reader_user.user.css_id)
            .and_return([appeal_with_doc1, appeal_with_doc2]).once

          expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc1, anything)
            .and_raise(Caseflow::Error::DocumentRetrievalError.new("<faultstring>Womp Womp.</faultstring>")).once

          expect { FetchDocumentsForReaderUserJob.perform_now(reader_user) }
            .to raise_error(Caseflow::Error::DocumentRetrievalError)
          expect(S3Service.files).to be_nil
        end
      end

      context "on second appeal" do
        let!(:expected_slack_msg) do
          "FetchDocumentsForReaderUserJob (user_id: #{current_user_id}) ERROR. " \
            "It retrieved 1 documents for 1 / 2 appeals and 0 document(s) failed.\n"
        end

        let!(:current_user_id) do
          reader_user_w_many_roles.user.id
        end

        it "throws an error and logs an error with status when a VBMS client error occurs" do
          expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
            .with(reader_user_w_many_roles.user.css_id)
            .and_return([appeal_with_doc1, appeal_with_doc2]).once

          # the first appeal should go through no problem
          expect_calls_for_appeal(appeal_with_doc1, expected_doc1, doc1_expected_content)

          expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc2, anything)
            .and_raise(Caseflow::Error::DocumentRetrievalError.new("<faultstring>Womp Womp.</faultstring>")).once

          expect { FetchDocumentsForReaderUserJob.perform_now(reader_user_w_many_roles) }
            .to raise_error(Caseflow::Error::DocumentRetrievalError)

          expect(S3Service.files[expected_doc1.vbms_document_id]).to eq(doc1_expected_content)
          expect(S3Service.files[expected_doc2.vbms_document_id]).to be_nil
          expect(S3Service.files[unexpected_document.vbms_document_id]).to be_nil
        end
      end
    end

    context "when HTTP Timeout occurs" do
      let!(:expected_slack_msg) do
        "FetchDocumentsForReaderUserJob (user_id: #{current_user_id}) ERROR. " \
          "It retrieved 1 documents for 1 / 2 appeals and 0 document(s) failed.\n"
      end

      let!(:current_user_id) do
        reader_user.user.id
      end

      it "throws an error to retry the job. Logging indicates error" do
        expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
          .with(reader_user.user.css_id)
          .and_return([appeal_with_doc1, appeal_with_doc2]).once

        # the first appeal should go through no problem
        expect_calls_for_appeal(appeal_with_doc1, expected_doc1, doc1_expected_content)

        expect(VBMSService).to receive(:fetch_documents_for).with(appeal_with_doc2, anything)
          .and_raise(HTTPClient::KeepAliveDisconnected.new("You lose.")).once

        expect { FetchDocumentsForReaderUserJob.perform_now(reader_user) }
          .to raise_error(HTTPClient::KeepAliveDisconnected)

        expect(S3Service.files[expected_doc1.vbms_document_id]).to eq(doc1_expected_content)
        expect(S3Service.files[expected_doc2.vbms_document_id]).to be_nil
        expect(S3Service.files[unexpected_document.vbms_document_id]).to be_nil
      end
    end

    context "when files exist in S3" do
      let!(:expected_slack_msg) do
        "FetchDocumentsForReaderUserJob (user_id: #{current_user_id}) SUCCESS. " \
          "It retrieved 0 documents for 2 / 2 appeals and 0 document(s) failed.\n"
      end

      let!(:current_user_id) do
        reader_user.user.id
      end

      it "does not fetch content" do
        allow(S3Service).to receive(:exists?).with(any_args).and_return(true)

        expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
          .with(reader_user.user.css_id)
          .and_return([appeal_with_doc1, appeal_with_doc2]).once

        struct = doc_struct.clone
        struct[:documents] = [expected_doc1]

        expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc1, reader_user.user)
          .and_return(struct).once

        struct[:documents] = [expected_doc2]
        expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc2, reader_user.user)
          .and_return(struct).once

        FetchDocumentsForReaderUserJob.perform_now(reader_user)
        expect(S3Service.files).to be_nil
      end
    end
    context "when S3 throws an exception" do
      let!(:expected_slack_msg) do
        "FetchDocumentsForReaderUserJob (user_id: #{current_user_id}) SUCCESS. " \
          "It retrieved 1 documents for 2 / 2 appeals and 1 document(s) failed.\n"
      end

      let!(:current_user_id) do
        reader_user.user.id
      end

      it "throws an exception and properly logs this" do
        expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
          .with(reader_user.user.css_id)
          .and_return([appeal_with_doc1, appeal_with_doc2]).once

        expect_calls_for_appeal(appeal_with_doc1, expected_doc1, doc1_expected_content)


        struct = doc_struct.clone
        struct[:documents] = [expected_doc2]

        expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc2, reader_user.user)
          .and_return(struct).once

        expect(expected_doc2).to receive(:fetch_content)
          .and_raise(VBMS::ClientError.new("Error")).once

        expect { FetchDocumentsForReaderUserJob.perform_now(reader_user) }
          .to_not raise_error(VBMS::ClientError)

        expect(S3Service.files[expected_doc1.vbms_document_id]).to eq(doc1_expected_content)
        expect(S3Service.files[expected_doc2.vbms_document_id]).to be_nil
        expect(S3Service.files[unexpected_document.vbms_document_id]).to be_nil
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
    struct = doc_struct.clone
    struct[:documents] = [doc]
    expect(EFolderService).to receive(:fetch_documents_for).with(appeal, anything).and_return(struct).once
    expect_calls_for_doc(doc, content)
  end

  def expect_calls_for_doc(doc, content)
    expect(S3Service).to receive(:exists?).with(doc.vbms_document_id).and_return(false).once
    expect(EFolderService).to receive(:fetch_document_file).with(doc).and_return(content).once
  end
end
