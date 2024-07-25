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

  describe ".update_document_in_vbms" do
    let(:fake_document) do
      instance_double(
        UpdateDocumentInVbms,
        document_type_id: 1,
        pdf_location: "/path/to/test/location",
        source: "my_source",
        document_series_reference_id: "{12345}"
      )
    end
    let(:appeal) { create(:appeal) }

    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      let(:mock_file_update_payload) { instance_double(ClaimEvidenceFileUpdatePayload) }

      it "calls the CE API" do
        expect(ClaimEvidenceFileUpdatePayload).to receive(:new).and_return(mock_file_update_payload)
        expect(VeteranFileUpdater)
          .to receive(:update_veteran_file)
          .with(
            veteran_file_number: appeal.veteran_file_number,
            file_uuid: "12345",
            file_update_payload: mock_file_update_payload
          )

        described.update_document_in_vbms(appeal, fake_document)
      end
    end

    context "with use_ce_api feature toggle disabled" do
      let(:mock_init_update_response) { double(updated_document_token: "document-token") }

      it "calls the SOAP API implementation" do
        expect(FeatureToggle).to receive(:enabled?).with(:use_ce_api).and_return(false)
        expect(described).to receive(:init_vbms_client)
        expect(described).to receive(:initialize_update).and_return(mock_init_update_response)
        expect(described).to receive(:update_document).with(
          appeal.veteran_file_number,
          "document-token",
          "/path/to/test/location"
        )

        described.update_document_in_vbms(appeal, fake_document)
      end
    end
  end
end
