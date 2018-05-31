require "rails_helper"
require "faker"

describe FetchDocumentsForReaderUserJob do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context ".perform" do
    let(:user) do
      Generators::User.create(roles: ["Reader"])
    end

    let!(:reader_user) do
      Generators::ReaderUser.create(user_id: user.id)
    end

    let(:document) { create(:document) }

    let(:appeal) do
      create(
        :legacy_appeal,
        vacols_case: create(:case, documents: [document], staff: create(:staff, sdomainid: user.css_id)))
    end

    let(:doc_struct) do
      {
        documents: [document]
      }
    end

    context "when a reader user with 1 appeal is provided" do
      it "retrieves the appeal document and updates the fetched at time" do
        expect(EFolderService).to receive(:fetch_documents_for).with(appeal, anything).and_return(doc_struct).once

        expect(reader_user.documents_fetched_at).to be_nil
        FetchDocumentsForReaderUserJob.perform_now(reader_user)
        expect(reader_user.documents_fetched_at).to_not be_nil
      end
    end

    context "when eFolder exception is thrown" do
      it "raises an error" do
        expect(EFolderService).to receive(:fetch_documents_for).with(appeal, anything)
          .and_raise(Caseflow::Error::DocumentRetrievalError.new("<faultstring>Womp Womp.</faultstring>")).once

        expect { FetchDocumentsForReaderUserJob.perform_now(reader_user) }
          .to raise_error(Caseflow::Error::DocumentRetrievalError)
      end
    end

    context "when efolder returns 403" do
      it "job does not raise an error" do
        allow(EFolderService).to receive(:fetch_documents_for).with(appeal, anything)
          .and_raise(Caseflow::Error::EfolderAccessForbidden)

        expect { FetchDocumentsForReaderUserJob.perform_now(reader_user) }.not_to raise_error
      end
    end

    context "when efolder returns 400" do
      it "job does not raise an error" do
        allow(EFolderService).to receive(:fetch_documents_for).with(appeal, anything)
          .and_raise(Caseflow::Error::ClientRequestError)

        expect { FetchDocumentsForReaderUserJob.perform_now(reader_user) }.not_to raise_error
      end
    end

    context "when HTTP Timeout occurs" do
      it "job raises an error" do
        allow(EFolderService).to receive(:fetch_documents_for).with(appeal, anything)
          .and_raise(HTTPClient::KeepAliveDisconnected.new("You lose."))

        expect { FetchDocumentsForReaderUserJob.perform_now(reader_user) }
          .to raise_error(HTTPClient::KeepAliveDisconnected)
      end
    end
  end
end
