# frozen_string_literal: true

require "faker"

describe FetchDocumentsForReaderUserJob, :all_dbs do
  context ".perform" do
    let(:user) { create(:user) }
    let(:document) { create(:document) }

    let(:appeal) do
      create(
        :legacy_appeal,
        vacols_case: create(:case, documents: [document], staff: create(:staff, sdomainid: user.css_id))
      )
    end

    let(:doc_struct) do
      {
        documents: [document]
      }
    end

    context "when a reader user with 1 legacy appeal is provided" do
      it "retrieves the appeal document and updates the fetched at time" do
        expect(EFolderService).to receive(:fetch_documents_for).with(appeal, anything).and_return(doc_struct).once

        expect(user.efolder_documents_fetched_at).to be_nil
        FetchDocumentsForReaderUserJob.perform_now(user)
        expect(user.efolder_documents_fetched_at).to_not be_nil
      end
    end

    context "when a reader user with 1 ama appeal is provided" do
      let(:ama_appeal) do
        create(
          :appeal,
          documents: [document]
        )
      end
      let!(:task) do
        create(
          :ama_attorney_task,
          :in_progress,
          assigned_to: user,
          appeal: ama_appeal
        )
      end
      it "retrieves the appeal document and updates the fetched at time" do
        expect(EFolderService).to receive(:fetch_documents_for).with(ama_appeal, anything).and_return(doc_struct).once

        expect(user.efolder_documents_fetched_at).to be_nil
        FetchDocumentsForReaderUserJob.perform_now(user)
        expect(user.efolder_documents_fetched_at).to_not be_nil
      end
    end

    context "when an attorney with a colocated task is provided" do
      let!(:vacols_atty) do
        create(
          :staff,
          :attorney_role,
          sdomainid: user.css_id
        )
      end
      let(:ama_appeal) do
        create(
          :appeal,
          documents: [document]
        )
      end
      let!(:task) do
        create(
          :colocated_task,
          assigned_to: create(:user),
          assigned_by: user,
          appeal: ama_appeal
        )
      end
      it "retrieves the appeal document and updates the fetched at time" do
        expect(EFolderService).to receive(:fetch_documents_for).with(ama_appeal, anything).and_return(doc_struct).once

        expect(user.efolder_documents_fetched_at).to be_nil
        FetchDocumentsForReaderUserJob.perform_now(user)
        expect(user.efolder_documents_fetched_at).to_not be_nil
      end
    end

    context "when eFolder exception is thrown" do
      it "does not raise an error" do
        msg = "<faultstring>Womp Womp.</faultstring>"
        expect(EFolderService).to receive(:fetch_documents_for).with(appeal, anything)
          .and_raise(Caseflow::Error::DocumentRetrievalError.new(code: 502, message: msg)).once

        expect { FetchDocumentsForReaderUserJob.perform_now(user) }.not_to raise_error
      end
    end

    context "when efolder returns 403" do
      it "job does not raise an error" do
        allow(EFolderService).to receive(:fetch_documents_for).with(appeal, anything)
          .and_raise(Caseflow::Error::EfolderAccessForbidden.new(code: 401, message: "error"))

        expect { FetchDocumentsForReaderUserJob.perform_now(user) }.not_to raise_error
      end
    end

    context "when efolder returns 400" do
      it "job does not raise an error" do
        allow(EFolderService).to receive(:fetch_documents_for).with(appeal, anything)
          .and_raise(Caseflow::Error::ClientRequestError.new(code: 400, message: "error"))

        expect { FetchDocumentsForReaderUserJob.perform_now(user) }.not_to raise_error
      end
    end

    context "when efolder does not recognize the veteran file number" do
      before do
        allow(EFolderService).to receive(:fetch_documents_for).with(appeal, anything)
          .and_raise(VBMS::FilenumberDoesNotExist.new(500, "error"))
      end

      it "does not raise error" do
        expect { FetchDocumentsForReaderUserJob.perform_now(user) }.not_to raise_error
      end
    end

    context "when HTTP Timeout occurs" do
      it "job raises an error" do
        allow(EFolderService).to receive(:fetch_documents_for).with(appeal, anything)
          .and_raise(HTTPClient::KeepAliveDisconnected.new("You lose."))

        expect { FetchDocumentsForReaderUserJob.perform_now(user) }
          .to raise_error(HTTPClient::KeepAliveDisconnected)
      end
    end
  end
end
