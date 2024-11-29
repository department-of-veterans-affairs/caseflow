# frozen_string_literal: true

describe ExternalApi::VefsApiClient do
  subject(:described) { described_class.new }

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:mock_http_client) { Faraday.new { |b| b.adapter(:test, stubs) } }

  before do
    allow(Faraday).to receive(:new).and_return(mock_http_client)
  end

  describe "#fetch_cmp_document_content_by_uuid" do
    let!(:cmp_document) { create(:cmp_document) }

    it "fetches the content for a CmpDocument" do
      stubs.get("/api/v1/rest/files/#{cmp_document.cmp_document_uuid}/content") do
        [
          200,
          { "Content-Type": "application/octet-stream" },
          "Test PDF response"
        ]
      end

      expect(described.fetch_cmp_document_content_by_uuid(cmp_document.cmp_document_uuid)).to eq("Test PDF response")
      stubs.verify_stubbed_calls
    end
  end
end
