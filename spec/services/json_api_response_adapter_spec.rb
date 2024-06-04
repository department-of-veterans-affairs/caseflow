# frozen_string_literal: true

require "json"

describe JsonApiResponseAdapter do
  subject(:described) { described_class.new }

  let(:api_response) { instance_double(ExternalApi::Response) }

  describe "#adapt_fetch_document_series_for" do
    it "correctly parses an API response" do
      file = File.open(Rails.root.join("spec/support/api_responses/ce_api_folders_files_search.json"))
      data_hash = JSON.parse(File.read(file))
      file.close

      expect(api_response).to receive(:body)
        .and_return(data_hash)

      parsed = described.adapt_fetch_document_series_for(api_response)

      expect(parsed.length).to eq 2

      expect(parsed[0].document_id).to eq "03223945-468b-4e8a-b79b-82fa73c2d2d9"
      expect(parsed[0].received_at).to eq "2018-03-08"
      expect(parsed[0].mime_type).to eq "application/pdf"

      expect(parsed[1].document_id).to eq "7d6afd8c-3bf7-4224-93ae-e1f07ac43c71"
      expect(parsed[1].received_at).to eq "2018-12-08"
      expect(parsed[1].mime_type).to eq "application/pdf"
    end
  end
end
