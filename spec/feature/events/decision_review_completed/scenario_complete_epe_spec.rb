# frozen_string_literal: true

# rubocop:disable Style/NumericLiterals
RSpec.describe Api::Events::V1::DecisionReviewCompletedController, type: :controller do
  describe "POST #decision_review_completed" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
    let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 1234567) }

    def json_test_payload
      {
        "event_id": 214706,
        "claim_id": 1234567,
        "css_id": "BVADWISE101",
        "detail_type": "HigherLevelReview",
        "station": "101",
        "claim_review": {
          "auto_remand": false,
          "remand_source_id": nil,
          "informal_conference": false,
          "same_office": false,
          "legacy_opt_in_approved": false
        },
        "end_product_establishment": {
          "code": "030HLRR",
          "development_item_reference_id": "1",
          "reference_id": "1234567",
          "synced_status": "CLR",
          "last_synced_at": 1726688419000
        },
        "completed_issues": nil
      }
    end

    let!(:valid_params) do
      json_test_payload
    end

    context "a payload that ONLY affects the EPE" do
      before do
        FeatureToggle.disable!(:disable_ama_eventing)
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
      end
      it "updates the EPE accordingly with a Cleared or Canceled status, indicating completion" do
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        post :decision_review_completed, params: valid_params
        expect(response).to have_http_status(:created)
        epe.reload
        expect(epe.code).to eq("030HLRR")
        expect(epe.synced_status).to eq("CLR")
        expect(epe.last_synced_at).to_not be_nil
      end
    end
  end
end

# rubocop:enable Style/NumericLiterals
