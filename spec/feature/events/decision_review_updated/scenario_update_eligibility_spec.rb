# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewUpdatedController, type: :controller do
  context "ineligible_to_eligible" do
    describe "POST #decision_review_updated" do
      let!(:current_user) { User.authenticate! }
      let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
      let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 12_345_678) }
      let(:review) { epe.source }
      let!(:existing_request_issue) do
        create(:request_issue,
               decision_review: review, reference_id: "1234", closed_at: nil,
               ineligible_reason: nil, contested_issue_description: nil,
               nonrating_issue_category: nil, nonrating_issue_description: nil)
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
          "withdrawn_issues": [],
          "ineligible_to_eligible_issues": [],
          "eligible_to_ineligible_issues": [
            {
              "original_caseflow_request_issue_id": 12_345,
              "contested_rating_decision_reference_id": nil,
              "contested_rating_issue_reference_id": nil,
              "contested_decision_issue_id": nil,
              "untimely_exemption": false,
              "untimely_exemption_notes": nil,
              "edited_description": "DIC: Service connection denied (UPDATED)",
              "vacols_id": nil,
              "vacols_sequence_id": nil,
              "nonrating_issue_bgs_id": nil,
              "type": "RequestIssue",
              "decision_review_issue_id": 1234,
              "contention_reference_id": 123_456,
              "benefit_type": "compensation",
              "contested_issue_description": "UPDATED DESCRIPTION",
              "contested_rating_issue_profile_date": nil,
              "decision_date": nil,
              "ineligible_due_to_id": nil,
              "ineligible_reason": "appeal_to_appeal",
              "unidentified_issue_text": "An unidentified issue added during the edit",
              "nonrating_issue_category": "Military Retired Pay",
              "nonrating_issue_description": "UPDATED TESTING",
              "closed_at": 1_702_000_145_000,
              "closed_status": nil,
              "contested_rating_issue_diagnostic_code": nil,
              "rating_issue_associated_at": nil,
              "ramp_claim_id": nil,
              "is_unidentified": true,
              "nonrating_issue_bgs_source": nil
            }
          ],
          "ineligible_to_ineligible_issues": []
        }
      end

      let!(:valid_params) do
        json_test_payload
      end

      context "updates issue" do
        before do
          request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        end

        it "returns success response whith ineligible request_issue" do
          request.headers["Authorization"] = "Token token=#{api_key.key_string}"
          post :decision_review_updated, params: valid_params
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("DecisionReviewUpdatedEvent successfully updated")
          existing_request_issue.reload

          expect(existing_request_issue.ineligible_reason).to eq("appeal_to_appeal")
          expect(existing_request_issue.contested_issue_description).to eq("UPDATED DESCRIPTION")
          expect(existing_request_issue.nonrating_issue_category).to eq("Military Retired Pay")
          expect(existing_request_issue.nonrating_issue_description).to eq("UPDATED TESTING")
          expect(existing_request_issue.closed_at).to eq("2023-12-07 20:49:05.000000000 -0500")
        end
      end
    end
  end

  context "eligible_to_ineligible" do
    describe "POST #decision_review_updated" do
      let!(:current_user) { User.authenticate! }
      let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
      let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 12_345_678) }
      let(:review) { epe.source }
      let!(:existing_request_issue) do
        create(:request_issue,
               decision_review: review, reference_id: "1234", closed_at: nil,
               ineligible_reason: nil, contested_issue_description: nil,
               nonrating_issue_category: nil, nonrating_issue_description: nil)
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
          "withdrawn_issues": [],
          "ineligible_to_eligible_issues": [],
          "eligible_to_ineligible_issues": [
            {
              "original_caseflow_request_issue_id": 12_345,
              "contested_rating_decision_reference_id": nil,
              "contested_rating_issue_reference_id": nil,
              "contested_decision_issue_id": nil,
              "untimely_exemption": false,
              "untimely_exemption_notes": nil,
              "edited_description": "DIC: Service connection denied (UPDATED)",
              "vacols_id": nil,
              "vacols_sequence_id": nil,
              "nonrating_issue_bgs_id": nil,
              "type": "RequestIssue",
              "decision_review_issue_id": 1234,
              "contention_reference_id": 123_456,
              "benefit_type": "compensation",
              "contested_issue_description": "Eligible UPDATED",
              "contested_rating_issue_profile_date": nil,
              "decision_date": nil,
              "ineligible_due_to_id": nil,
              "ineligible_reason": nil,
              "unidentified_issue_text": "An unidentified issue added during the edit",
              "nonrating_issue_category": "Military Retired Pay ELIGIBLE",
              "nonrating_issue_description": "UPDATED ELIGIBLE",
              "closed_at": 1_702_000_145_000,
              "closed_status": "removed",
              "contested_rating_issue_diagnostic_code": nil,
              "rating_issue_associated_at": nil,
              "ramp_claim_id": nil,
              "is_unidentified": true,
              "nonrating_issue_bgs_source": nil
            }
          ],
          "ineligible_to_ineligible_issues": []
        }
      end

      let!(:valid_params) do
        json_test_payload
      end

      context "updates issue" do
        before do
          request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        end

        it "returns success response whith ineligible request_issue" do
          request.headers["Authorization"] = "Token token=#{api_key.key_string}"
          post :decision_review_updated, params: valid_params
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("DecisionReviewUpdatedEvent successfully updated")
          existing_request_issue.reload

          expect(existing_request_issue.ineligible_reason).to eq(nil)
          expect(existing_request_issue.contested_issue_description).to eq("Eligible UPDATED")
          expect(existing_request_issue.nonrating_issue_category).to eq("Military Retired Pay ELIGIBLE")
          expect(existing_request_issue.nonrating_issue_description).to eq("UPDATED ELIGIBLE")
          expect(existing_request_issue.closed_at).to eq("2023-12-07 20:49:05.000000000 -0500")
          expect(existing_request_issue.closed_status).to eq("removed")
        end
      end
    end
  end

end
