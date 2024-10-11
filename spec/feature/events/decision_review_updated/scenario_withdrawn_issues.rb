# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewUpdatedController, type: :controller do
  let!(:current_user) { User.authenticate! }
  let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
  let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 12_345_678) }
  let(:review) { epe.source }

  context "tests processing withdrawn request issues" do
    describe "POST #decision_review_updated" do
      let!(:withdrawn_request_issue) do
        create(:request_issue,
               decision_review: review, reference_id: "1234", closed_status: nil, closed_at: nil,
               contention_removed_at: nil, contention_reference_id: 100_500)
      end

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
          "updated_issues": [],
          "removed_issues": [],
          "withdrawn_issues": [
            {
              "original_caseflow_request_issue_id": 12_345,
              "contested_rating_decision_reference_id": nil,
              "contested_rating_issue_reference_id": nil,
              "contested_decision_issue_id": nil,
              "untimely_exemption": false,
              "untimely_exemption_notes": nil,
              "vacols_id": nil,
              "vacols_sequence_id": nil,
              "nonrating_issue_bgs_id": nil,
              "type": "RequestIssue",
              "decision_review_issue_id": 1234,
              "contention_reference_id": 123_456,
              "benefit_type": "compensation",
              "contested_issue_description": nil,
              "contested_rating_issue_profile_date": nil,
              "decision_date": nil,
              "ineligible_due_to_id": nil,
              "ineligible_reason": nil,
              "unidentified_issue_text": "An unidentified issue added during the edit",
              "nonrating_issue_category": nil,
              "nonrating_issue_description": nil,
              "closed_at": 1_702_000_145_000,
              "closed_status": nil,
              "contested_rating_issue_diagnostic_code": nil,
              "rating_issue_associated_at": nil,
              "ramp_claim_id": nil,
              "is_unidentified": true,
              "nonrating_issue_bgs_source": nil
            }
          ],
          "ineligible_to_eligible_issues": [],
          "eligible_to_ineligible_issues": [],
          "ineligible_to_ineligible_issues": []
        }
      end

      let!(:valid_params) do
        json_test_payload
      end

      context "withdrawn issue with already existing issue not edited or withdrawn" do
        let!(:existing_request_issue) do
          create(:request_issue, decision_review: review, reference_id: "6789")
        end
        before do
          request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        end

        it "returns success response whith updated closed_at date" do
          expect(withdrawn_request_issue.reference_id).to eq("1234")
          expect(withdrawn_request_issue.closed_at).to eq(nil)
          expect(withdrawn_request_issue.contention_reference_id).to eq(100_500)
          expect(withdrawn_request_issue.any_updates?).to eq(false)
          post :decision_review_updated, params: valid_params
          expect(response).to have_http_status(:created)
          expect(response.body).to include("DecisionReviewUpdatedEvent successfully processed")
          withdrawn_request_issue.reload
          expect(withdrawn_request_issue.closed_at).to eq("2023-12-07 20:49:05.000000000 -0500")
          expect(withdrawn_request_issue.closed_status).to eq("withdrawn")
          expect(withdrawn_request_issue.any_updates?).to eq(true)
          expect(withdrawn_request_issue.updated_at).to be_within(100.seconds).of(DateTime.now)
          request_issue_update = review.request_issues_updates.first
          expect(request_issue_update.withdrawn_request_issue_ids).to eq([withdrawn_request_issue.id])
          expect(request_issue_update.before_request_issue_ids).to eq(
            [withdrawn_request_issue.id, existing_request_issue.id]
          )
          expect(request_issue_update.after_request_issue_ids).to eq(
            [withdrawn_request_issue.id, existing_request_issue.id]
          )
          expect(request_issue_update.edited_request_issue_ids).to eq([])
        end
      end
    end
  end
end
