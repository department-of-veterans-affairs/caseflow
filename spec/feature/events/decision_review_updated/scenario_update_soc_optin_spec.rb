# frozen_string_literal: true

# rubocop:disable Style/NumericLiterals

RSpec.describe Api::Events::V1::DecisionReviewUpdatedController, type: :controller do
  describe "POST #decision_review_updated" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
    let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 1234567) }
    let!(:hlr) { epe.source }
    let!(:epe_2) { create(:end_product_establishment, :active_supp, reference_id: 9876543) }
    let!(:sc) { epe_2.source }

    def json_test_payload
      {
        "event_id": 214706,
        "claim_id": 1234567,
        "css_id": "BVADWISE101",
        "detail_type": "HigherLevelReview",
        "station": "101",
        "claim_review": {
          "informal_conference": false,
          "same_office": false,
          "legacy_opt_in_approved": true
        },
        "end_product_establishment": {
          "code": "030HLRR",
          "development_item_reference_id": "1",
          "reference_id": "1234567"
        },
        "added_issues": nil,
        "updated_issues": nil,
        "removed_issues": nil,
        "withdrawn_issues": nil,
        "ineligible_to_eligible_issues": nil,
        "eligible_to_ineligible_issues": nil,
        "ineligible_to_ineligible_issues": nil
      }
    end

    def json_test_payload_2
      {
        "event_id": 214707,
        "claim_id": 9876543,
        "css_id": "BVADWISE101",
        "detail_type": "SupplementalClaim",
        "station": "101",
        "claim_review": {
          "informal_conference": false,
          "same_office": false,
          "legacy_opt_in_approved": true
        },
        "end_product_establishment": {
          "reference_id": "9876543"
        }
      }
    end

    let!(:valid_params) do
      json_test_payload
    end

    let!(:valid_params_2) do
      json_test_payload_2
    end

    context "a payload that ONLY affects the soc optin on the claim review" do
      before do
        FeatureToggle.disable!(:disable_ama_eventing)
      end
      it "updates the HLR accordingly" do
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        post :decision_review_updated, params: valid_params
        expect(response).to have_http_status(:ok)
        hlr.reload
        expect(hlr.legacy_opt_in_approved).to eq(true)
      end
      it "also updates SC's accordingly" do
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        post :decision_review_updated, params: valid_params_2
        expect(response).to have_http_status(:ok)
        sc.reload
        expect(sc.legacy_opt_in_approved).to eq(true)
      end
    end
  end
end

# rubocop:enable Style/NumericLiterals
