# frozen_string_literal: true

require "json"

describe JsonApiResponseAdapter do
  subject(:described) { described_class.new }

  let(:api_response) { instance_double(ExternalApi::Response) }

  describe "#adapt_fetch_document_series_for" do
    context "with invalid responses" do
      it "handles blank responses" do
        parsed = described.adapt_fetch_document_series_for(nil)

        expect(parsed.length).to eq 0
      end

      it "handles blank response bodies" do
        response = instance_double(ExternalApi::Response, body: nil)
        parsed = described.adapt_fetch_document_series_for(response)

        expect(parsed.length).to eq 0
      end

      it "handles response bodies with no files" do
        response = instance_double(ExternalApi::Response, body: {})
        parsed = described.adapt_fetch_document_series_for(response)

        expect(parsed.length).to eq 0
      end
    end

    it "correctly parses an API response" do
      file = File.open(Rails.root.join("spec/support/api_responses/ce_api_folders_files_search.json"))
      data_hash = JSON.parse(File.read(file))
      file.close

      expect(api_response).to receive(:body)
        .exactly(3).times.and_return(data_hash)

      parsed = described.adapt_fetch_document_series_for(api_response)

      expect(parsed.length).to eq 2

      expect(parsed[0].document_id).to eq "{03223945-468B-4E8A-B79B-82FA73C2D2D9}"
      expect(parsed[0].received_at).to eq "2018/03/08"
      expect(parsed[0].mime_type).to eq "application/pdf"

      expect(parsed[1].document_id).to eq "{7D6AFD8C-3BF7-4224-93AE-E1F07AC43C71}"
      expect(parsed[1].received_at).to eq "2018/12/08"
      expect(parsed[1].mime_type).to eq "application/pdf"
    end
  end
end
