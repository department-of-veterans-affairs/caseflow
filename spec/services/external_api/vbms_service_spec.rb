# frozen_string_literal: true

describe ExternalApi::VBMSService do
  subject(:described) { described_class }

  describe ".fetch_document_series_for" do
    let(:mock_json_adapter) { instance_double(JsonApiResponseAdapter) }
    let(:mock_vbms_document_series_for_appeal) { instance_double(ExternalApi::VbmsDocumentSeriesForAppeal) }

    let!(:appeal) { create(:appeal) }

    before do
      allow(JsonApiResponseAdapter).to receive(:new).and_return(mock_json_adapter)
      allow(ExternalApi::VbmsDocumentSeriesForAppeal).to receive(:new).and_return(mock_vbms_document_series_for_appeal)
    end

    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      it "calls the CE API" do
        expect(VeteranFileFetcher).to receive(:fetch_veteran_file_list)
          .with(veteran_file_number: appeal.veteran_file_number)
        expect(mock_json_adapter).to receive(:adapt_fetch_document_series_for).and_return([])

        described.fetch_document_series_for(appeal)
      end
    end

    context "with no feature toggles enabled" do
      it "calls the VbmsDocumentSeriesForAppeal service" do
        expect(FeatureToggle).to receive(:enabled?).with(:use_ce_api).and_return(false)
        expect(ExternalApi::VbmsDocumentSeriesForAppeal).to receive(:new).with(file_number: appeal.veteran_file_number)
        expect(mock_vbms_document_series_for_appeal).to receive(:fetch)

        described.fetch_document_series_for(appeal)
      end
    end
  end

  describe ".fetch_document_for" do
    let(:mock_json_adapter) { instance_double(JsonApiResponseAdapter) }
    let!(:appeal) { create(:appeal) }

    before do
      allow(JsonApiResponseAdapter).to receive(:new).and_return(mock_json_adapter)
    end

    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      it "calls the CE API" do
        expect(VeteranFileFetcher).to receive(:fetch_veteran_file_list)
          .with(veteran_file_number: appeal.veteran_file_number)
        expect(mock_json_adapter).to receive(:adapt_fetch_document_series_for).and_return([])
        described.fetch_document_series_for(appeal)
      end
    end
  end

  describe ".fetch_document_file" do
    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      let(:fake_document) do
        Generators::Document.build(id: 201, type: "NOD", series_id: "{ABC-123}")
      end

      it "calls the CE API" do
        expect(VeteranFileFetcher)
          .to receive(:get_document_content)
          .with(doc_series_id: fake_document.series_id)
          .and_return("Pdf Byte String")

        described.fetch_document_file(fake_document)
      end
    end
  end
end
