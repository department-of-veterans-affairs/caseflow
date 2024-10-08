# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewUpdatedController, type: :controller do
  describe "POST #decision_review_updated" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
    let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 12_345_678) }
    let(:review) { epe.source }
    let!(:existing_request_issue) { create(:request_issue, decision_review: review, reference_id: "6789") }

    def json_test_payload
      {
        "event_id": 214_786,
        "claim_id": 12_345_678,
        "css_id": "BVADWISE101",
        "detail_type": "HigherLevelReview",
        "station": "101",
        "intake": {
          "started_at": 1_702_067_143_435,
          "completion_started_at": 1_702_067_145_000,
          "completed_at": 1_702_067_145_000,
          "completion_status": "success",
          "type": "HigherLevelReviewIntake",
          "detail_type": "HigherLevelReview"
        },
        "veteran": {
          "participant_id": "1826209",
          "bgs_last_synced_at": 1_708_533_584_000,
          "name_suffix": nil,
          "date_of_death": nil
        },
        "claimant": {
          "payee_code": "00",
          "type": "VeteranClaimant",
          "participant_id": "1826209",
          "name_suffix": nil
        },
        "claim_review": {
          "benefit_type": "compensation",
          "filed_by_va_gov": false,
          "legacy_opt_in_approved": false
        },
        "end_product_establishment": {
          "code": "030HLRNR",
          "reference_id": "12345678",
          "last_synced_at": 1_702_067_145_000,
          "synced_status": "RFD",
          "development_item_reference_id": "1"
        },
        "added_issues": [
          {
            "original_caseflow_request_issue_id": nil,
            "contested_rating_decision_reference_id": nil,
            "contested_rating_issue_reference_id": nil,
            "contested_decision_issue_id": nil,
            "untimely_exemption": false,
            "untimely_exemption_notes": "some notes",
            "edited_description": nil,
            "vacols_id": "some_id",
            "vacols_sequence_id": "some_sequence_id",
            "nonrating_issue_bgs_id": "some_bgs_id",
            "type": "RequestIssue",
            "decision_review_issue_id": 1234,
            "contention_reference_id": 123_456,
            "benefit_type": "compensation",
            "contested_issue_description": "some_description",
            "contested_rating_issue_profile_date": "122255",
            "decision_date": 19_568,
            "ineligible_due_to_id": nil,
            "ineligible_reason": nil,
            "unidentified_issue_text": "An unidentified issue added during the edit",
            "nonrating_issue_category": nil,
            "nonrating_issue_description": nil,
            "closed_at": nil,
            "closed_status": nil,
            "contested_rating_issue_diagnostic_code": "9411",
            "rating_issue_associated_at": nil,
            "ramp_claim_id": nil,
            "is_unidentified": true,
            "nonrating_issue_bgs_source": nil
          }
        ],
        "updated_issues": [],
        "removed_issues": [],
        "withdrawn_issues": [],
        "ineligible_to_eligible_issues": [],
        "eligible_to_ineligible_issues": [],
        "ineligible_to_ineligible_issues": []
      }
    end

    let!(:valid_params) do
      json_test_payload
    end

    context "add issue with already existing issue" do
      before do
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
      end

      it "returns success response whith updated edited_description" do
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        expect(existing_request_issue.edited_description).to_not eq("DIC: Service connection denied (UPDATED)")
        post :decision_review_updated, params: valid_params
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("DecisionReviewUpdatedEvent successfully processed")
        existing_request_issue.reload
        expect(existing_request_issue.any_updates?).to eq(true)
        new_request_issue = RequestIssue.find_by(reference_id: "1234")
        expect(new_request_issue).to be
        request_issue_update = review.request_issues_updates.first
        expect(request_issue_update).to be
        expect(request_issue_update.before_request_issue_ids).to eq([existing_request_issue.id])
        expect(request_issue_update.after_request_issue_ids).to eq([new_request_issue.id, existing_request_issue.id])
        expect(request_issue_update.edited_request_issue_ids).to eq([])
        expect(request_issue_update.withdrawn_request_issue_ids).to eq([])
        expect(new_request_issue.event_records.last.info["update_type"]).to eq("A")
        expect(new_request_issue.event_records.last.info["record_data"]["id"]).to eq(new_request_issue.id)
      end
    end
  end
end
