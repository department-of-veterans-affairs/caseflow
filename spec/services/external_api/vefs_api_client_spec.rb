# frozen_string_literal: true

describe ExternalApi::VefsApiClient do
  subject(:described) { described_class.new }

  describe "#fetch_cmp_document_content_by_uuid" do
    let!(:cmp_document) { create(:cmp_document) }

    let!(:token_endpoint) { "/api/v1/rest/api/v1/token" }
    let!(:doc_content_endpoint) { "/api/v1/rest/files/#{cmp_document.cmp_document_uuid}/content" }

    let!(:bearer_token_header) { { "Authorization": "Bearer 1234" } }

    # Can't use verifying doubles here since HTTParty::Response wraps Net::HTTPResponse
    # and the success? method is dynamically created
    # (see https://github.com/jnunemaker/httparty/issues/456)
    let(:token_response) { double(success?: true, body: "1234") }
    let(:doc_content_response) { double(success?: true, body: "Test PDF response") }

    it "fetches the content for a CmpDocument" do
      expect(described_class).to receive(:post)
        .with(token_endpoint, body: instance_of(String), headers: instance_of(Hash))
        .and_return(token_response)
      expect(described_class).to receive(:get)
        .with(doc_content_endpoint, headers: bearer_token_header, query: instance_of(Hash))
        .and_return(doc_content_response)
      expect(MetricsService).to receive(:record).and_call_original

      expect(described.fetch_cmp_document_content_by_uuid(cmp_document.cmp_document_uuid)).to eq("Test PDF response")
    end

    context "with HTTP error" do
      let(:mock_error_reporter) { instance_double(ErrorHandlers::VefsApiErrorHandler) }
      let(:http_error) { HTTParty::ResponseError.new(Net::HTTPNotFound) }

      before do
        allow(ErrorHandlers::VefsApiErrorHandler).to receive(:new).and_return(mock_error_reporter)
      end

      it "reports HTTP errors" do
        expect(described_class).to receive(:post)
          .with(token_endpoint, body: instance_of(String), headers: instance_of(Hash))
          .and_return(token_response)
        expect(described_class).to receive(:get)
          .with(doc_content_endpoint, headers: bearer_token_header, query: instance_of(Hash))
          .and_raise(http_error)
        expect(Rails.logger).to receive(:error).with(http_error)
        expect(mock_error_reporter).to receive(:handle_error).with(error: http_error, error_details: instance_of(Hash))

        expect(described.fetch_cmp_document_content_by_uuid(cmp_document.cmp_document_uuid)).to be_blank
      end
    end
  end
end
