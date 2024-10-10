# frozen_string_literal: true

require "rails_helper"

describe ExternalApi::VBMSService do
  subject(:described) { described_class }
  let(:mock_json_adapter) { instance_double(JsonApiResponseAdapter) }
  let(:mock_sensitivity_checker) { instance_double(SensitivityChecker, sensitivity_levels_compatible?: true) }
  let!(:user) do
    user = create(:user)
    RequestStore.store[:current_user] = user
  end

  before do
    allow(JsonApiResponseAdapter).to receive(:new).and_return(mock_json_adapter)
    allow(SensitivityChecker).to receive(:new).and_return(mock_sensitivity_checker)
  end

  describe ".verify_current_user_veteran_access" do
    let!(:appeal) { create(:appeal) }

    it "checks the user's sensitivity" do
      expect(mock_sensitivity_checker).to receive(:sensitivity_levels_compatible?)
        .with(user: user, veteran: appeal.veteran).and_return(true)

      described.verify_current_user_veteran_access(appeal.veteran)
    end

    it "does not check sensitivity if the user is not present" do
      RequestStore.store[:current_user] = nil

      expect(mock_sensitivity_checker).not_to receive(:sensitivity_levels_compatible?)

      described.verify_current_user_veteran_access(appeal.veteran)
    end

    it "raises an exception when the sensitivity levels are not compatible" do
      expect(mock_sensitivity_checker).to receive(:sensitivity_levels_compatible?)
        .with(user: user, veteran: appeal.veteran).and_return(false)

      expect { described.verify_current_user_veteran_access(appeal.veteran) }
        .to raise_error(BGS::SensitivityLevelCheckFailure, "User does not have permission to access this information")
    end
  end

  describe ".fetch_document_series_for" do
    let(:mock_vbms_document_series_for_appeal) { instance_double(ExternalApi::VbmsDocumentSeriesForAppeal) }
    let!(:appeal) { create(:appeal) }

    before do
      allow(ExternalApi::VbmsDocumentSeriesForAppeal).to receive(:new).and_return(mock_vbms_document_series_for_appeal)
    end

    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      it "calls the CE API" do
        expect(mock_sensitivity_checker).to receive(:sensitivity_levels_compatible?)
          .with(user: user, veteran: appeal.veteran).and_return(true)
        expect(VeteranFileFetcher).to receive(:fetch_veteran_file_list)
          .with(
            veteran_file_number: appeal.veteran_file_number,
            claim_evidence_request: instance_of(ClaimEvidenceRequest)
          )
        expect(mock_json_adapter).to receive(:adapt_fetch_document_series_for).and_return([])

        described.fetch_document_series_for(appeal)
      end
    end

    context "with use_ce_api feature toggle disabled" do
      it "calls the VbmsDocumentSeriesForAppeal service" do
        expect(FeatureToggle).to receive(:enabled?).with(:use_ce_api).and_return(false)
        expect(ExternalApi::VbmsDocumentSeriesForAppeal).to receive(:new).with(file_number: appeal.veteran_file_number)
        expect(mock_vbms_document_series_for_appeal).to receive(:fetch)

        described.fetch_document_series_for(appeal)
      end
    end
  end

  describe ".fetch_documents_for" do
    let(:mock_vbms_document_series_for_appeal) { instance_double(ExternalApi::VbmsDocumentsForAppeal) }
    let!(:appeal) { create(:appeal) }

    before do
      allow(ExternalApi::VbmsDocumentsForAppeal).to receive(:new).and_return(mock_vbms_document_series_for_appeal)
    end

    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      it "calls the CE API" do
        expect(mock_sensitivity_checker).to receive(:sensitivity_levels_compatible?)
          .with(user: user, veteran: appeal.veteran).and_return(true)
        expect(VeteranFileFetcher).to receive(:fetch_veteran_file_list)
          .with(
            veteran_file_number: appeal.veteran_file_number,
            claim_evidence_request: instance_of(ClaimEvidenceRequest)
          )
        expect(mock_json_adapter).to receive(:adapt_fetch_document_series_for).and_return([])

        described.fetch_documents_for(appeal)
      end
    end

    context "with use_ce_api feature toggle disabled" do
      it "calls the VbmsDocumentsForAppeal service" do
        expect(FeatureToggle).to receive(:enabled?).with(:use_ce_api).and_return(false)
        expect(ExternalApi::VbmsDocumentsForAppeal).to receive(:new).with(file_number: appeal.veteran_file_number)
        expect(mock_vbms_document_series_for_appeal).to receive(:fetch)

        described.fetch_documents_for(appeal)
      end
    end
  end

  describe ".fetch_document_file" do
    let!(:appeal) { create(:appeal) }
    let(:fake_document) do
      Generators::Document.build(id: 201, type: "NOD", series_id: "{ABC-123}", file_number: appeal.veteran.file_number)
    end

    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      it "calls the CE API" do
        expect(mock_sensitivity_checker).to receive(:sensitivity_levels_compatible?)
          .with(user: user, veteran: appeal.veteran).and_return(true)
        expect(VeteranFileFetcher)
          .to receive(:get_document_content)
          .with(doc_series_id: fake_document.series_id, claim_evidence_request: instance_of(ClaimEvidenceRequest))
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
        document_series_reference_id: "{12345}",
        document_subject: "testing1"
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
            claim_evidence_request: instance_of(ClaimEvidenceRequest),
            file_uuid: "12345",
            file_update_payload: mock_file_update_payload
          )
        expect(mock_json_adapter).to receive(:adapt_update_document)

        described.update_document_in_vbms(appeal, fake_document)
      end
    end

    context "with use_ce_api feature toggle disabled" do
      let(:mock_init_update_response) { double(updated_document_token: "document-token") }

      it "calls the SOAP API implementation" do
        expect(FeatureToggle).to receive(:enabled?).with(:use_ce_api).and_return(false)
        expect(described).to receive(:init_vbms_client)
        expect(described).to receive(:initialize_update).and_return(mock_init_update_response)
        expect(described).to receive(:send_and_log_request)
          .with(appeal.veteran_file_number, instance_of(VBMS::Requests::UpdateDocument))

        described.update_document_in_vbms(appeal, fake_document)
      end
    end
  end

  describe ".upload_document_to_vbms" do
    let(:fake_document) do
      instance_double(
        "UploadDocumentToVbms",
        pdf_location: "/path/to/test/location",
        source: "my_source",
        document_type_id: 1,
        document_type: "test",
        document_subject: "testing1",
        new_mail: true
      )
    end
    let(:appeal) { create(:appeal) }

    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      let(:mock_file_upload_payload) { instance_double("ClaimEvidenceFileUploadPayload") }

      it "calls the CE API" do
        allow(SecureRandom).to receive(:uuid).and_return("12345")
        # rubocop:disable Rails/TimeZone
        allow(Time).to receive(:current).and_return(Time.parse("2024-07-26"))
        # rubocop:enable Rails/TimeZone
        filename = "12345location"

        expect(ClaimEvidenceFileUploadPayload).to receive(:new).with(
          content_name: filename,
          content_source: fake_document.source,
          date_va_received_document: "2024-07-26",
          document_type_id: fake_document.document_type_id,
          subject: fake_document.document_type,
          new_mail: true
        ).and_return(mock_file_upload_payload)

        expect(VeteranFileUploader).to receive(:upload_veteran_file).with(
          file_path: fake_document.pdf_location,
          claim_evidence_request: instance_of(ClaimEvidenceRequest),
          veteran_file_number: appeal.veteran_file_number,
          doc_info: mock_file_upload_payload
        )
        expect(mock_json_adapter).to receive(:adapt_upload_document)
        described_class.upload_document_to_vbms(appeal, fake_document)
      end
    end

    context "with use_ce_api feature toggle disabled" do
      before { FeatureToggle.disable!(:use_ce_api) }

      let(:mock_vbms_client) { instance_double("VBMS::Client") }
      let(:mock_initialize_upload_response) { double(upload_token: "document-token") }

      it "calls the VBMS client" do
        allow(described_class).to receive(:init_vbms_client).and_return(mock_vbms_client)
        allow(described_class).to receive(:initialize_upload)
          .with(appeal, fake_document).and_return(mock_initialize_upload_response)
        allow(described_class).to receive(:upload_document)
          .with(appeal.veteran_file_number, "document-token", fake_document.pdf_location)

        described_class.upload_document_to_vbms(appeal, fake_document)

        expect(described_class).to have_received(:initialize_upload).with(appeal, fake_document)
        expect(described_class).to have_received(:upload_document)
          .with(appeal.veteran_file_number, "document-token", fake_document.pdf_location)
      end
    end
  end

  describe ".claim_evidence_request" do
    context "with send_current_user_cred_to_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:send_current_user_cred_to_ce_api) }

      context "when current_user is set in the RequestStore" do
        let(:user) do
          user = create(:user)
          RequestStore[:current_user] = user
        end

        it "returns user credentials" do
          result = described.claim_evidence_request

          expect(result.user_css_id).to eq user.css_id
          expect(result.station_id).to eq user.station_id
        end
      end

      context "when current_user is NOT set in the RequestStore" do
        before do
          RequestStore[:current_user] = nil
          ENV["CLAIM_EVIDENCE_VBMS_USER"] = "CSS_123"
          ENV["CLAIM_EVIDENCE_STATION_ID"] = "123"
        end

        it "returns system credentials" do
          result = described.claim_evidence_request

          expect(result.user_css_id).to eq "CSS_123"
          expect(result.station_id).to eq "123"
        end
      end
    end

    context "with send_current_user_cred_to_ce_api feature toggle disabled" do
      before do
        FeatureToggle.disable!(:send_current_user_cred_to_ce_api)
        ENV["CLAIM_EVIDENCE_VBMS_USER"] = "CSS_999"
        ENV["CLAIM_EVIDENCE_STATION_ID"] = "999"
      end

      context "when current_user is set in the RequestStore" do
        let(:user) do
          user = create(:user)
          RequestStore[:current_user] = user
        end

        it "returns system credentials" do
          result = described.claim_evidence_request

          expect(result.user_css_id).to eq "CSS_999"
          expect(result.station_id).to eq "999"
        end
      end

      context "when current_user is NOT set in the RequestStore" do
        before { RequestStore[:current_user] = nil }

        it "returns system credentials" do
          result = described.claim_evidence_request

          expect(result.user_css_id).to eq "CSS_999"
          expect(result.station_id).to eq "999"
        end
      end
    end
  end
end
