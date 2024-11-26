# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewCompletedController, type: :controller do
  describe "POST #decision_review_completed" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
    let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 20_010_065) }

    def json_test_payload
      {
        "css_id": "BVADWISE",
        "detail_type": "HigherLevelReview",
        "station": "101",
        "claim_id": 20_010_065,
        "event_id": 1_234_567,
        "end_product_establishment": {
          "synced_status": "CLR",
          "last_synced_at": 1_702_067_145_000,
          "code": "030HLRR",
          "development_item_reference_id": null,
          "reference_id": "20010065"
        },
        "claim_review": {
          "auto_remand": null,
          "remand_source_id": null,
          "informal_conference": null,
          "same_office": null,
          "legacy_opt_in_approved": false
        },
        "completed_issues": [
          "id": 12,
          "benefit_type": "compensation",
          "closed_at": 1_702_067_145_000,
          "closed_status": "closed",
          "contention_reference_id": 7_905_752,
          "contested_issue_description": null,
          "contested_rating_issue_diagnostic_code": null,
          "contested_rating_issue_reference_id": null,
          "contested_rating_issue_profile_date": null,
          "contested_decision_issue_id": 12_345,
          "decision_date": 18_475,
          "decision_review_issue_id": 1_234,
          "is_unidentified": null,
          "unidentified_issue_text": "unidentified text",
          "nonrating_issue_bgs_id": "13",
          "nonrating_issue_bgs_source": "CORP_AWARD_ATTORNEY_FEE",
          "nonrating_issue_category": "Accrued Benefits",
          "nonrating_issue_description": "The user entered description if the issue is a nonrating issue",
          "original_caseflow_request_issue_id": 12_345,
          "ramp_claim_id": null,
          "rating_issue_associated_at": null,
          "type": "RequestIssue",
          "untimely_exemption": null,
          "untimely_exemption_notes": null,
          "vacols_id": null,
          "vacols_sequence_id": null,
          "veteran_participant_id": "210002659",
          "decision_issue": {
            "benefit_type": "compensation",
            "decision_text": "service connected",
            "description": null,
            "diagnostic_code": null,
            "disposition": "Granted",
            "end_product_last_action_date": 19_594,
            "participant_id": "1826209",
            "percent_number": "50",
            "rating_issue_reference_id": null,
            "rating_profile_date": null,
            "rating_promulgation_date": null,
            "subject_text": "This broadcast may not be reproduced"
          }
        ]
      }
    end

    let!(:valid_params) do
      json_test_payload
    end

    let!(:invalid_params) do
      {
        "css_id": null,
        "detail_type": "BLA",
        "station": "SPACE",
        "event_id": null,
        "end_product_establishment": {
          "synced_status": "Something",
          "last_synced_at": null,
          "code": "ERROR",
          "development_item_reference_id": null,
          "reference_id": "20010065"
        },
        "claim_review": {},
        "completed_issues": [
          "id": null,
          "decision_issue": {}
        ]
      }
    end

    context "updates issue scenario_hlr_1_eligible_nonrating_issue" do
      before do
        FeatureToggle.disable!(:disable_ama_eventing)
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
      end

      it "returns success response scenario_hlr_1_eligible_nonrating_issue" do
        post :decision_review_completed, params: valid_params
        expect(response).to have_http_status(:completed)
        expect(response.body).to include("DecisionReviewCompletedEvent successfully processed")
        completed_request_issue = RequestIssue.find_by(reference_id: "1234")
        expect(completed_request_issue).to be
        expect(completed_request_issue.nonrating_issue_category).to eq("Accrued Benefits")
        expect(completed_request_issue.nonrating_issue_description)
          .to eq("The user entered description if the issue is a nonrating issue")
        expect(completed_request_issue.nonrating_issue_bgs_source).to eq("CORP_AWARD_ATTORNEY_FEE")
        expect(completed_request_issue.nonrating_issue_bgs_id).to eq("13")
        expect(completed_request_issue.rating_issue_associated_at).to eq(nil)
        expect(completed_request_issue.closed_at).to eq(1_702_067_145_000)
        expect(completed_request_issue.closed_status).to eq("closed")
        expect(completed_request_issue.contested_issue_description).to eq(nil)
        expect(completed_request_issue.contention_reference_id).to eq(7_905_752)
        expect(completed_request_issue.contested_rating_issue_profile_date).to eq(nil)
        expect(completed_request_issue.contested_rating_issue_reference_id).to eq(nil)
        expect(completed_request_issue.vacols_id).to eq(nil)
        expect(completed_request_issue.vacols_sequence_id).to eq(nil)
        # decision_issue = DecisionIssue.joins(:request_issues).find_by(request_issues: { reference_id: "1234" })
        decision_issue = completed_request_issue.decision_issues.last
        expect(decision_issue.benefit_type).to eq("compensation")
        expect(decision_issue.decision_text).to eq("service connected")
        expect(decision_issue.description).to eq(nil)
        expect(decision_issue.diagnostic_code).to eq(nil)
        expect(decision_issue.disposition).to eq("Granted")
        expect(decision_issue.end_product_last_action_date).to eq(19_594)
        expect(decision_issue.participant_id).to eq("1826209")
        expect(decision_issue.percent_number).to eq("50")
        expect(decision_issue.rating_issue_reference_id).to eq(nil)
        expect(decision_issue.rating_profile_date).to eq(nil)
        expect(decision_issue.rating_promulgation_date).to eq(nil)
        expect(decision_issue.subject_text).to eq("This broadcast may not be reproduced")
        epe = EndProductEstablishment.find_by(reference_id: "20010065")
        expect(epe.synced_status).to eq("CLR")
        expect(epe.last_synced_at).to eq(1_702_067_145_000)
        expect(epe.code).to eq("030HLRR")
        expect(epe.development_item_reference_id).to eq(nil)
        review = epe.source
        expect(review.auto_remand).to eq(nil)
        expect(review.informal_conference).to eq(nil)
        expect(review.same_office).to eq(nil)
        expect(review.legacy_opt_in_approved).to eq(false)
      end
    end

    context "API disabled" do
      before do
        FeatureToggle.enable!(:disable_ama_eventing)
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
      end

      it "when api is disabled" do
        post :decision_review_completed, params: valid_params
        expect(response).to have_http_status(501)
        expect(response.body).to include("API is disabled")
      end
    end

    context "Handling of duplicate events" do
      before do
        FeatureToggle.disable!(:disable_ama_eventing)
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
      end

      it "returns record already exists in Caseflow" do
        load_headers
        2.times { post :decision_review_completed, params: valid_params }
        expect(response).to have_http_status(:conflict)
        expect(response.body).to include("Record already exists in Caseflow")
      end
    end

    context "does not complete on error" do
      before do
        FeatureToggle.disable!(:disable_ama_eventing)
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        allow_any_instance_of(DecisionIssuesCompleteEvent).to receive(:perform!).and_raise(StandardError.new("Error"))
      end

      it "returns error" do
        post :decision_review_updated, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Error")
      end
    end

    context "does not complete with invalid params" do
      before do
        FeatureToggle.disable!(:disable_ama_eventing)
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
      end

      it "returns error" do
        post :decision_review_updated, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Error")
      end
    end
  end
end
