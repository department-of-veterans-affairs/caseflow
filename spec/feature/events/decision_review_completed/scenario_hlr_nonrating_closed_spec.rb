# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewCompletedController, type: :controller do
  describe "POST #decision_review_completed" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
    # let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 337_534) }
    # let(:review) { epe.source }
    # let!(:existing_request_issue) { create(:request_issue, :ineligible, decision_review: review, reference_id: "1234")}

    def json_test_payload
      {
        "css_id": "BVADWISE",
        "detail_type": "HigherLevelReview",
        "station": "101",
        "event_id": 1234567,
        "end_product_establishment": {
          "synced_status": "CLR",
          "last_synced_at": 1702067145000,
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
          "closed_at": 1702067145000,
          "closed_status": "closed",
          "contention_reference_id": 7905752,
          "contested_issue_description": null,
          "contested_rating_issue_diagnostic_code": null,
          "contested_rating_issue_reference_id": null,
          "contested_rating_issue_profile_date": null,
          "contested_decision_issue_id": 12345,
          "decision_date": 18475,
          "decision_review_issue_id": 908,
          "is_unidentified": null,
          "unidentified_issue_text": "unidentified text",
          "nonrating_issue_bgs_id": "13",
          "nonrating_issue_bgs_source": "CORP_AWARD_ATTORNEY_FEE",
          "nonrating_issue_category": "Accrued Benefits",
          "nonrating_issue_description": "The user entered description if the issue is a nonrating issue",
          "original_caseflow_request_issue_id": 12345,
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
            "contention_reference_id": 7905752,
            "decision_text": "service connected",
            "description": null,
            "diagnostic_code": null,
            "disposition": "Granted",
            "end_product_last_action_date": 19594,
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

    context "updates issue scenario_hlr_1_eligible_nonrating_issue" do
      before do
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
      end

      it "returns success response scenario_hlr_1_eligible_nonrating_issue" do
        # post :decision_review_completed, params: valid_params
        # expect(response).to have_http_status(:completed)
        # expect(response.body).to include("DecisionReviewcompletedEvent successfully processed")
        # completed_request_issue = RequestIssue.find_by(reference_id: "1234")
        # expect(completed_request_issue).to be
        # expect(completed_request_issue.nonrating_issue_category).to eq("Accrued Benefits")
        # expect(completed_request_issue.nonrating_issue_description).to eq("The user entered description if the issue is a nonrating issue")
        # expect(completed_request_issue.nonrating_issue_bgs_source).to eq("CORP_AWARD_ATTORNEY_FEE")
        # expect(completed_request_issue.nonrating_issue_bgs_id).to eq("13")
        # expect(completed_request_issue.rating_issue_associated_at).to eq(nil)
        # expect(completed_request_issue.closed_at).to eq(nil)
        # expect(completed_request_issue.closed_status).to eq(nil)
        # expect(completed_request_issue.contested_issue_description).to eq(nil)
        # expect(completed_request_issue.contention_reference_id).to eq(7_905_752)
        # expect(completed_request_issue.contested_rating_decision_reference_id).to eq(nil)
        # expect(completed_request_issue.contested_rating_issue_profile_date).to eq(nil)
        # expect(completed_request_issue.contested_rating_issue_reference_id).to eq(nil)
        # expect(completed_request_issue.vacols_id).to eq(nil)
        # expect(completed_request_issue.vacols_sequence_id).to eq(nil)
        # epe = EndProductEstablishment.find_by(reference_id: "337534")
        # review = epe.source
        # veteran = epe.veteran
        # id = epe.claimant_participant_id
        # claimant = Claimant.find_by(participant_id: id)
        # expect(epe.synced_status).to eq("RW")
        # expect(epe.limited_poa_access).to eq(nil)
        # expect(epe.limited_poa_code).to eq(nil)
        # expect(veteran.participant_id).to eq("1826209")
        # expect(veteran.bgs_last_synced_at).to eq(1_708_533_584_000)
        # expect(veteran.name_suffix).to eq(nil)
        # expect(veteran.date_of_death).to eq(nil)
        # expect(review.auto_remand).to eq(nil)
        # expect(review.establishment_attempted_at).to eq(1_702_067_145_000)
        # expect(review.establishment_last_submitted_at).to eq(1_702_067_145_000)
        # expect(review.establishment_processed_at).to eq(1_702_067_145_000)
        # expect(review.establishment_submitted_at).to eq(1_702_067_145_000)
        # expect(review.informal_conference).to eq(false)
        # expect(review.same_office).to eq(false)
        # expect(review.legacy_opt_in_approved).to eq(false)
        # expect(claimant.type).to eq("VeteranClaimant")
        # expect(claimant.payee_code).to eq("00")
        # expect(claimant.participant_id).to eq("1826209")
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

    context "does not comlete on error" do
      before do
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        allow_any_instance_of(DecisionIssuesCompleteEvent).to receive(:perform!).and_raise(StandardError.new("Error"))
      end

      it "returns " do
        post :decision_review_updated, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Error")
      end
    end
  end
end
