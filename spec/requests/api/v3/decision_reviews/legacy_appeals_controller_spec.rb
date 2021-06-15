# frozen_string_literal: true

describe Api::V3::DecisionReviews::LegacyAppealsController, :all_dbs, type: :request do
  before { FeatureToggle.enable!(:api_v3_legacy_appeals) }
  after { FeatureToggle.disable!(:api_v3_legacy_appeals) }

  let(:api_key) { ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string }

  let(:vacols_id) { "123456789" }

  let(:valid_soc_date) { Time.zone.today - 40.days }

  let(:ama_date) { Constants::DATES["AMA_ACTIVATION"].to_date }
  let(:invalid_soc_date) { ama_date - 380.days }
  let(:invalid_soc_date2) { Time.zone.today - 70.days }
  let(:invalid_ssoc_date) { ama_date - 1.year }

  let!(:eligible_active_case) do
    create(:case, :status_active, bfcorlid: "#{vacols_id}S", bfdsoc: valid_soc_date)
  end

  let!(:ineligible_active_case) do
    create(:case, :status_active, bfcorlid: "#{vacols_id}S", bfdsoc: invalid_soc_date2)
  end

  let!(:eligible_complete_case) do
    create(:case, :status_complete, bfcorlid: "#{vacols_id}S", bfdsoc: valid_soc_date)
  end

  let!(:ineligible_complete_case) do
    create(:case, :status_complete, bfcorlid: "#{vacols_id}S", bfdsoc: invalid_soc_date, bfssoc1: invalid_ssoc_date)
  end

  let!(:eligible_active_legacy_appeal) do
    create(:legacy_appeal, :with_veteran, vbms_id: "#{vacols_id}S", vacols_case: eligible_active_case)
  end

  let!(:eligible_complete_legacy_appeal) do
    create(:legacy_appeal, vbms_id: "#{vacols_id}S", vacols_case: eligible_complete_case)
  end

  let!(:ineligible_active_legacy_appeal) do
    create(:legacy_appeal, vbms_id: "#{vacols_id}S", vacols_case: ineligible_active_case)
  end

  let!(:ineligible_complete_legacy_appeal) do
    create(:legacy_appeal, vbms_id: "#{vacols_id}S", vacols_case: ineligible_complete_case)
  end

  let(:veteran) { eligible_active_legacy_appeal.veteran }

  let!(:unrelated_legacy_appeal) do
    create(:legacy_appeal, :with_veteran, vbms_id: "987654321S", vacols_case: create(:case, bfcorlid: "987654321S"))
  end

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
