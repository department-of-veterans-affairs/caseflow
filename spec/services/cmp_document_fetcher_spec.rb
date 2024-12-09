# frozen_string_literal: true

describe CmpDocumentFetcher do
  subject(:described) { described_class.new }

  let(:mock_vefs_api_client) { instance_double(ExternalApi::VefsApiClient) }

  before do
    allow(ExternalApi::VefsApiClient).to receive(:new).and_return(mock_vefs_api_client)
  end

  describe "#get_cmp_document_content" do
    let!(:cmp_document) { create(:cmp_document) }

    it "fetches the content for a CmpDocument" do
      expect(mock_vefs_api_client).to receive(:fetch_cmp_document_content_by_uuid)
        .with(cmp_document.cmp_document_uuid).and_return("Test PDF content")

      expect(described.get_cmp_document_content(cmp_document.cmp_document_uuid)).to eq("Test PDF content")
    end

    it "caches fetched documents" do
      expect(mock_vefs_api_client).to receive(:fetch_cmp_document_content_by_uuid)
        .once
        .with(cmp_document.cmp_document_uuid).and_return("Test PDF content")

      expect(described.get_cmp_document_content(cmp_document.cmp_document_uuid)).to eq("Test PDF content")
      expect(described.get_cmp_document_content(cmp_document.cmp_document_uuid)).to eq("Test PDF content")
    end

    context "with error" do
      let(:mock_error_reporter) { instance_double(ErrorHandlers::VefsApiErrorHandler) }
      let(:mock_error) { StandardError.new("Test error") }

      before do
        allow(ErrorHandlers::VefsApiErrorHandler).to receive(:new).and_return(mock_error_reporter)
      end

      it "reports HTTP errors" do
        expect(mock_vefs_api_client).to receive(:fetch_cmp_document_content_by_uuid)
          .with(cmp_document.cmp_document_uuid).and_raise(mock_error)
        expect(Rails.logger).to receive(:error).with(mock_error)
        expect(mock_error_reporter).to receive(:handle_error).with(error: mock_error, error_details: instance_of(Hash))

        expect(described.get_cmp_document_content(cmp_document.cmp_document_uuid)).to be_blank
      end
    end
  end
end
