# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewUpdatedController, type: :controller do
  let!(:current_user) { User.authenticate! }
  let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
  let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 12_345_678) }
  let(:review) { epe.source }

  context "tests processing removed request issues" do
    describe "POST #decision_review_updated" do
      let!(:removed_request_issue) do
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
          "removed_issues": [
            {
              "original_caseflow_request_issue_id": 1,
              "decision_review_issue_id": 1234,
              "closed_at": 1_702_000_145_000,
              "closed_status": "removed"
            }
          ],
          "withdrawn_issues": [],
          "ineligible_to_eligible_issues": [],
          "eligible_to_ineligible_issues": [],
          "ineligible_to_ineligible_issues": []
        }
      end

      let!(:valid_params) do
        json_test_payload
      end

      context "removed issue with already existing issue not edited or removed" do
        let!(:existing_request_issue) do
          create(:request_issue, decision_review: review, reference_id: "6789", edited_description: "edited")
        end
        before do
          request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        end

        it "returns success response whith updated closed_at date" do
          expect(removed_request_issue.reference_id).to eq("1234")
          expect(removed_request_issue.closed_at).to eq(nil)
          expect(removed_request_issue.contention_reference_id).to eq(100_500)
          expect(removed_request_issue.any_updates?).to eq(false)
          expect(existing_request_issue.edited_description).to eq("edited")
          post :decision_review_updated, params: valid_params
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("DecisionReviewUpdatedEvent successfully processed")
          removed_request_issue.reload
          expect(removed_request_issue.closed_at).to eq("2023-12-07 20:49:05.000000000 -0500")
          expect(removed_request_issue.closed_status).to eq("removed")
          expect(removed_request_issue.any_updates?).to eq(true)
          expect(removed_request_issue.updated_at).to be_within(100.seconds).of(DateTime.now)
          request_issue_update = review.request_issues_updates.first
          expect(request_issue_update.withdrawn_request_issue_ids).to eq([])
          expect(request_issue_update.before_request_issue_ids).to eq(
            [removed_request_issue.id, existing_request_issue.id]
          )
          expect(request_issue_update.after_request_issue_ids).to eq(
            [existing_request_issue.id]
          )
          expect(request_issue_update.edited_request_issue_ids).to eq([])
          expect(existing_request_issue.edited_description).to eq("edited")
        end
      end
    end
  end
end
