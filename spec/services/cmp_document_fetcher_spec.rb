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
  end
end
