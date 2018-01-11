require "rails_helper"
require "faker"

describe FetchDocumentsForReaderUserJob do
  before(:all) do
    User.appeal_repository = Fakes::AppealRepository
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

    let!(:efolder_fetched_at_format) { "%FT%T.%LZ" }

    let!(:service_manifest_vbms_fetched_at) do
      Time.zone.local(1989, "nov", 23, 8, 2, 55).strftime(efolder_fetched_at_format)
    end

    let!(:service_manifest_vva_fetched_at) do
      Time.zone.local(1989, "dec", 13, 20, 15, 1).strftime(efolder_fetched_at_format)
    end

    let!(:doc_struct) do
      {
        manifest_vbms_fetched_at: service_manifest_vbms_fetched_at,
        manifest_vva_fetched_at: service_manifest_vva_fetched_at
      }
    end

    let!(:log_type) { :info }

    before do
      # Fail test if Mock is called for non-reader user
      expect(Fakes::AppealRepository).not_to receive(:load_user_case_assignments_from_vacols)
        .with(non_reader_user.css_id)
      dont_expect_calls_for_appeal(appeal_with_doc_for_non_reader, unexpected_document)

      # Expect all tests to call Slack service at the end
      expect(Rails.logger).to receive(log_type).with(expected_log_msg).once
    end

    context "when a reader user with 1 appeal is provided" do
      let!(:expected_log_msg) do
        "FetchDocumentsForReaderUserJob (user_id: #{current_user_id}) SUCCESS. " \
        "Retrieved 1 / 1 appeals"
      end

      context "the user has one reader role" do
        let!(:current_user_id) do
          reader_user.user.id
        end
        it "retrieves the appeal document" do
          expect_all_calls_for_user(reader_user.user, appeal_with_doc1, expected_doc1, doc1_expected_content)
          FetchDocumentsForReaderUserJob.perform_now(reader_user)
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
        end
      end
    end

    context "when eFolder exception is thrown" do
      context "on the first appeal" do
        let!(:log_type) { :error }
        let!(:expected_log_msg) do
          "FetchDocumentsForReaderUserJob (user_id: #{current_user_id}) ERROR. " \
            "Retrieved 0 / 2 appeals"
        end
        let!(:current_user_id) do
          reader_user.user.id
        end

        it "returns an ERROR log with status when a eFolder client error occurs" do
          expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
            .with(reader_user.user.css_id)
            .and_return([appeal_with_doc1, appeal_with_doc2]).once

          expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc1, anything)
            .and_raise(Caseflow::Error::DocumentRetrievalError.new("<faultstring>Womp Womp.</faultstring>")).once

          expect { FetchDocumentsForReaderUserJob.perform_now(reader_user) }
            .to raise_error(Caseflow::Error::DocumentRetrievalError)
        end
      end

      context "on second appeal" do
        let!(:log_type) { :error }
        let!(:expected_log_msg) do
          "FetchDocumentsForReaderUserJob (user_id: #{current_user_id}) ERROR. " \
            "Retrieved 1 / 2 appeals"
        end

        let!(:current_user_id) do
          reader_user_w_many_roles.user.id
        end

        it "throws an error and logs an error with status when a EfolderX error occurs" do
          expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
            .with(reader_user_w_many_roles.user.css_id)
            .and_return([appeal_with_doc1, appeal_with_doc2]).once

          # the first appeal should go through no problem
          expect_calls_for_appeal(appeal_with_doc1, expected_doc1, doc1_expected_content)

          expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc2, anything)
            .and_raise(Caseflow::Error::DocumentRetrievalError.new("<faultstring>Womp Womp.</faultstring>")).once

          expect { FetchDocumentsForReaderUserJob.perform_now(reader_user_w_many_roles) }
            .to raise_error(Caseflow::Error::DocumentRetrievalError)
        end
      end
    end

    context "when efolder returns 403 response for one of many appeals" do
      let(:appeals) { [Generators::Appeal.create, Generators::Appeal.create, Generators::Appeal.create] }
      let(:expected_log_msg) do
        "FetchDocumentsForReaderUserJob (user_id: #{current_user_id}) SUCCESS. " \
          "Retrieved #{appeal_cnt_successful} / #{appeal_cnt_total} appeals"
      end
      let(:current_user_id) { reader_user.user.id }
      let(:appeal_cnt_total) { appeals.count }
      let(:appeal_cnt_successful) { appeals.count - 1 }

      it "returns an ERROR log with status when a eFolder client error occurs" do
        expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
          .with(reader_user.user.css_id).and_return(appeals).once

        allow(EFolderService).to receive(:fetch_documents_for).and_call_original
        allow(EFolderService).to receive(:fetch_documents_for).with(appeals[0], anything)
          .and_raise(Caseflow::Error::EfolderAccessForbidden)

        expect { FetchDocumentsForReaderUserJob.perform_now(reader_user) }.not_to raise_error
      end
    end

    context "when HTTP Timeout occurs" do
      let!(:log_type) { :error }
      let!(:expected_log_msg) do
        "FetchDocumentsForReaderUserJob (user_id: #{current_user_id}) ERROR. " \
          "Retrieved 1 / 2 appeals"
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

        expect(EFolderService).to receive(:fetch_documents_for).with(appeal_with_doc2, anything)
          .and_raise(HTTPClient::KeepAliveDisconnected.new("You lose.")).once

        expect { FetchDocumentsForReaderUserJob.perform_now(reader_user) }
          .to raise_error(HTTPClient::KeepAliveDisconnected)
      end
    end
  end

  context "fetch_documents_for_appeals" do
    context "one appeal of many returns 403 from efolder" do
      let(:appeals) { [Generators::Appeal.create, Generators::Appeal.create, Generators::Appeal.create] }
      let(:err) { Caseflow::Error::EfolderAccessForbidden }

      subject { FetchDocumentsForReaderUserJob.new }
      it "continues fetching docs for other appeals and records failed fetch" do
        # This is usually set in perform(), but we are bypassing perform() so set it here.
        subject.instance_variable_set(:@counts, appeals_total: 0, appeals_successful: 0)

        allow(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols).and_return(appeals).once

        allow(EFolderService).to receive(:fetch_documents_for).and_call_original
        allow(EFolderService).to receive(:fetch_documents_for).with(appeals[0], anything).and_raise(err)

        expect(subject.fetch_documents_for_appeals(appeals)).to eq(appeals)

        expect(subject.instance_variable_get(:@counts)[:appeals_total]).to eq(appeals.count)
        expect(subject.instance_variable_get(:@counts)[:appeals_successful]).to eq(appeals.count - 1)
      end
    end
  end

  def dont_expect_calls_for_appeal(appeal, doc)
    expect(EFolderService).not_to receive(:fetch_documents_for).with(appeal, anything)
    expect(EFolderService).not_to receive(:fetch_document_file).with(doc)
  end

  def expect_all_calls_for_user(user, appeal, doc, content)
    expect(Fakes::AppealRepository).to receive(:load_user_case_assignments_from_vacols)
      .with(user.css_id)
      .and_return([appeal]).once
    expect_calls_for_appeal(appeal, doc, content)
  end

  def expect_calls_for_appeal(appeal, doc, _content)
    struct = doc_struct.clone
    struct[:documents] = [doc]
    expect(EFolderService).to receive(:fetch_documents_for).with(appeal, anything).and_return(struct).once
  end
end
