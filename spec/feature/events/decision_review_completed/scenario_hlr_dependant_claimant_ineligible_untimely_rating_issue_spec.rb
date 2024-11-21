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
        "event_id": "1",
        "css_id": "EVERECVACO",
        "detail_type": "HigherLevelReview",
        "station": "101",
        "intake": {
          "started_at": 1_702_067_143_435,
          "completion_started_at": 1_708_533_584_000,
          "completed_at": 1_708_533_584_000,
          "completion_status": "success",
          "type": "HigherLevelReviewIntake",
          "detail_type": "HigherLevelReview"
        },
        "veteran": {
          "participant_id": "1826209",
          "bgs_last_synced_at": 1_708_533_584_000,
          "name_suffix": null,
          "date_of_death": null
        },
        "claimant": {
          "payee_code": "11",
          "type": "DependentClaimant",
          "participant_id": "1129318238",
          "name_suffix": null
        },
        "claim_review": {
          "auto_remand": null,
          "benefit_type": "compensation",
          "filed_by_va_gov": false,
          "legacy_opt_in_approved": false,
          "receipt_date": 19_594,
          "veteran_is_not_claimant": true,
          "establishment_attempted_at": 1_708_533_584_000,
          "establishment_last_submitted_at": 1_708_533_584_000,
          "establishment_processed_at": 1_708_533_584_000,
          "establishment_submitted_at": 1_708_533_584_000,
          "informal_conference": false,
          "same_office": null
        },
        "end_product_establishment": {
          "benefit_type_code": "1",
          "claim_date": 19_594,
          "code": "030HLRR",
          "modifier": "030",
          "payee_code": "11",
          "reference_id": "474697",
          "limited_poa_access": null,
          "limited_poa_code": null,
          "committed_at": 1_708_533_584_000,
          "established_at": 1_708_533_584_000,
          "last_synced_at": 1_708_533_584_000,
          "synced_status": "RW",
          "development_item_reference_id": null
        },
        "request_issues": [
          {
            "decision_review_issue_id": "1",
            "benefit_type": "compensation",
            "contested_issue_description": "Left knee",
            "contention_reference_id": null,
            "contested_rating_decision_reference_id": null,
            "contested_rating_issue_profile_date": "2017-02-07T07:21:24+00:00",
            "contested_rating_issue_reference_id": "18262093449376",
            "contested_decision_issue_id": null,
            "decision_date": 17_490,
            "ineligible_due_to_id": null,
            "ineligible_reason": "untimely",
            "is_unidentified": false,
            "unidentified_issue_text": null,
            "nonrating_issue_category": null,
            "nonrating_issue_description": null,
            "remand_source_id": null,
            "untimely_exemption": false,
            "untimely_exemption_notes": null,
            "vacols_id": null,
            "vacols_sequence_id": null,
            "closed_at": 1_708_533_584_000,
            "closed_status": "ineligible",
            "contested_rating_issue_diagnostic_code": "5008",
            "ramp_claim_id": null,
            "rating_issue_associated_at": null,
            "nonrating_issue_bgs_id": null,
            "nonrating_issue_bgs_source": "CORP_AWARD_ATTORNEY_FEE"
          }
        ]
      }
    end

    let!(:valid_params) do
      json_test_payload
    end

    context "updates issue hlr_dependant_claimant_ineligible_untimely_rating_issue" do
      before do
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
      end

      it "returns success response hlr_dependant_claimant_ineligible_untimely_rating_issue" do
        # expect(existing_request_issue.edited_description).to_not eq("DIC: Service connection denied (UPDATED)")
        post :decision_review_completed, params: valid_params
        expect(response).to have_http_status(:completed)
        expect(response.body).to include("DecisionReviewcompletedEvent successfully processed")
        existing_request_issue.reload
        completed_request_issue = RequestIssue.find_by(reference_id: "1234")
        expect(completed_request_issue.nonrating_issue_category).to eq(nil)
        expect(completed_request_issue.nonrating_issue_description).to eq(nil)
        expect(completed_request_issue.nonrating_issue_bgs_source).to eq("CORP_AWARD_ATTORNEY_FEE")
        expect(completed_request_issue.nonrating_issue_bgs_id).to eq(nil)
        expect(completed_request_issue.rating_issue_associated_at).to eq(nil)
        expect(completed_request_issue.closed_at).to eq(1_708_533_584_000)
        expect(completed_request_issue.closed_status).to eq("ineligible")
        expect(completed_request_issue.contested_issue_description).to eq("Left knee")
        expect(completed_request_issue.contention_reference_id).to eq(nil)
        expect(completed_request_issue.contested_rating_decision_reference_id).to eq(nil)
        expect(completed_request_issue.contested_rating_issue_profile_date).to eq("2017-02-07T07:21:24+00:00")
        expect(completed_request_issue.contested_rating_issue_reference_id).to eq("18262093449376")
        expect(completed_request_issue.vacols_id).to eq(nil)
        expect(completed_request_issue.vacols_sequence_id).to eq(nil)
        epe = EndProductEstablishment.find_by(reference_id: "474697")
        review = epe.source
        veteran = epe.veteran
        id = epe.claimant_participant_id
        claimant = Claimant.find_by(participant_id: id)
        expect(epe.synced_status).to eq("RW")
        expect(epe.limited_poa_access).to eq(nil)
        expect(epe.limited_poa_code).to eq(nil)
        expect(veteran.participant_id).to eq("1826209")
        expect(veteran.bgs_last_synced_at).to eq(1_708_533_584_000)
        expect(veteran.name_suffix).to eq(nil)
        expect(veteran.date_of_death).to eq(nil)
        expect(review.auto_remand).to eq(nil)
        expect(review.establishment_attempted_at).to eq(1_708_533_584_000)
        expect(review.establishment_last_submitted_at).to eq(1_708_533_584_000)
        expect(review.establishment_processed_at).to eq(1_708_533_584_000)
        expect(review.establishment_submitted_at).to eq(1_708_533_584_000)
        expect(review.informal_conference).to eq(false)
        expect(review.same_office).to eq(nil)
        expect(review.legacy_opt_in_approved).to eq(false)
        expect(claimant.type).to eq("DependentClaimant")
        expect(claimant.payee_code).to eq("11")
        expect(claimant.participant_id).to eq("1129318238")
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
  end
end
