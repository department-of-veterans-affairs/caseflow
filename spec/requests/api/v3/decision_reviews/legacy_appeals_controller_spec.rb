# frozen_string_literal: true

describe Api::V3::DecisionReviews::LegacyAppealsController, :all_dbs, type: :request do
  before { FeatureToggle.enable!(:api_v3_legacy_appeals) }
  after { FeatureToggle.disable!(:api_v3_legacy_appeals) }

  let(:api_key) { ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string }

  let(:vbms_id) { "123456789S" }

  let(:valid_soc_date) { Time.zone.today - 40.days }

  let(:ama_date) { Constants::DATES["AMA_ACTIVATION"].to_date }
  let(:invalid_soc_date) { ama_date - 380.days }
  let(:invalid_soc_date2) { Time.zone.today - 70.days }
  let(:invalid_ssoc_date) { ama_date - 1.year }

  # CASES
  let!(:eligible_case) { create(:case, bfcorlid: vbms_id, bfdsoc: valid_soc_date) }

  let!(:eligible_case_2) { create(:case, bfcorlid: vbms_id, bfdsoc: valid_soc_date) }

  let!(:ineligible_case) { create(:case, bfcorlid: vbms_id, bfdsoc: invalid_soc_date2) }

  let!(:ineligible_case_2) { create(:case, bfcorlid: vbms_id, bfdsoc: invalid_soc_date, bfssoc1: invalid_ssoc_date) }

  # LEGACY APPEALS
  let!(:eligible_appeal) { create(:legacy_appeal, :with_veteran, vbms_id: vbms_id, vacols_case: eligible_case) }

  let!(:eligible_appeal_2) { create(:legacy_appeal, vbms_id: vbms_id, vacols_case: eligible_case_2) }

  let!(:ineligible_soc_date_appeal) { create(:legacy_appeal, vbms_id: vbms_id, vacols_case: ineligible_case) }

  let!(:ineligible_ssoc_date_appeal) { create(:legacy_appeal, vbms_id: vbms_id, vacols_case: ineligible_case_2) }

  let!(:unrelated_veteran_appeal) { create(:legacy_appeal, vbms_id: "987654321S") }

  let(:veteran) { eligible_appeal.veteran }

  describe "#index" do
    context "when SSN supplied" do
      it "returns legacy appeals associated with the veteran" do
        get_legacy_appeals(ssn: veteran.ssn)
        legacy_appeals = JSON.parse(response.body)["data"]

        expect(response).to have_http_status(:ok)
        expect(legacy_appeals.size).to eq 2
      end

      context "when file number supplied" do
        it "returns legacy appeals associated with the veteran" do
          get_legacy_appeals(file_number: veteran.file_number)
          legacy_appeals = JSON.parse(response.body)["data"]

          expect(response).to have_http_status(:ok)
          expect(legacy_appeals.size).to eq 2
          expect(legacy_appeals[0]["id"]).to eq eligible_appeal.vacols_id
          expect(legacy_appeals[1]["id"]).to eq eligible_appeal_2.vacols_id
        end
      end

      context "when neither ssn nor file_number provided" do
        it "returns a 422 error" do
          get_legacy_appeals
          errors = JSON.parse(response.body)["errors"][0]

          expect(errors["status"]).to eq 422
          expect(errors["title"]).to eq "Veteran file number or SSN header is required"
        end
      end

      context "when ssn is incorrectly formatted" do
        it "returns a 422 error" do
          get_legacy_appeals(ssn: "0F-3GVC")
          errors = JSON.parse(response.body)["errors"][0]

          expect(errors["status"]).to eq 422
          expect(errors["code"]).to eq "invalid_veteran_ssn"
        end
      end

      context "when veteran does not exist" do
        it "returns 404 error" do
          get_legacy_appeals(ssn: "123456781")
          errors = JSON.parse(response.body)["errors"][0]

          expect(errors["status"]).to eq 404
          expect(errors["code"]).to eq "veteran_not_found"
        end
      end
    end

    def get_legacy_appeals(ssn: nil, file_number: nil)
      headers = { "Authorization": "Token #{api_key}", "X-VA-File-Number": file_number, "X-VA-SSN": ssn }

      get("/api/v3/decision_reviews/legacy_appeals", headers: headers)
    end
  end
end
