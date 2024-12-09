# frozen_string_literal: true

require "json"

describe JsonApiResponseAdapter do
  subject(:described) { described_class.new }

  describe "#adapt_fetch_document_series_for" do
    context "with invalid responses" do
      it "handles blank responses" do
        parsed = described.adapt_fetch_document_series_for(nil)

        expect(parsed.length).to eq 0
      end

      it "handles responses with no files" do
        parsed = described.adapt_fetch_document_series_for({})

        expect(parsed.length).to eq 0
      end
    end

    it "correctly parses an API response" do
      file = File.open(Rails.root.join("spec/support/api_responses/ce_api_folders_files_search.json"))
      data_hash = JSON.parse(File.read(file))
      file.close

      parsed = described.adapt_fetch_document_series_for(data_hash)

      expect(parsed.length).to eq 2

      expect(parsed[0].document_id).to eq "{03223945-468B-4E8A-B79B-82FA73C2D2D9}"
      expect(parsed[0].received_at).to eq "2018/03/08"
      expect(parsed[0].mime_type).to eq "application/pdf"

      expect(parsed[1].document_id).to eq "{7D6AFD8C-3BF7-4224-93AE-E1F07AC43C71}"
      expect(parsed[1].received_at).to eq "2018/12/08"
      expect(parsed[1].mime_type).to eq "application/pdf"
    end
  end

  describe "adapt_upload_document" do
    it "correctly parses an API response" do
      data_hash = {
        "currentVersionUuid": "7D6AFD8C-3BF7-4224-93AE-E1F07AC43C71",
        "uuid": "03223945-468B-4E8A-B79B-82FA73C2D2D9"
      }.to_json

      parsed = described.adapt_upload_document(data_hash)

      expect(parsed[:upload_document_response][:@new_document_version_ref_id])
        .to eq "7D6AFD8C-3BF7-4224-93AE-E1F07AC43C71"
      expect(parsed[:upload_document_response][:@document_series_ref_id]).to eq "03223945-468B-4E8A-B79B-82FA73C2D2D9"
    end
  end

  describe "adapt_update_document" do
    it "correctly parses an API response" do
      data_hash = {
        "currentVersionUuid": "7D6AFD8C-3BF7-4224-93AE-E1F07AC43C71",
        "uuid": "03223945-468B-4E8A-B79B-82FA73C2D2D9"
      }.to_json

      parsed = described.adapt_update_document(data_hash)

      expect(parsed[:update_document_response][:@new_document_version_ref_id])
        .to eq "7D6AFD8C-3BF7-4224-93AE-E1F07AC43C71"
      expect(parsed[:update_document_response][:@document_series_ref_id]).to eq "03223945-468B-4E8A-B79B-82FA73C2D2D9"
    end
  end
end
