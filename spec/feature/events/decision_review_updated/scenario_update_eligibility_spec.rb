# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewUpdatedController, type: :controller do
  let!(:current_user) { User.authenticate! }
  let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
  let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 12_345_678) }
  let(:review) { epe.source }

  context "tests processing ineligible_to_eligible request issues" do
    describe "POST #decision_review_updated" do
      let!(:ineligible_to_eligible_request_issue) do
        create(:request_issue,
               decision_review: review, reference_id: "1234", closed_status: "ineligible", closed_at: DateTime.now,
               ineligible_reason: "appeal_to_appeal", contention_removed_at: DateTime.now,
               contested_issue_description: "original description", nonrating_issue_category: "original category",
               nonrating_issue_description: "original nonrating description", contention_reference_id: 100_500)
      end
      let!(:event2) { DecisionReviewCreatedEvent.create!(reference_id: "2") }
      let!(:request_issue_event_record) do
        EventRecord.create!(event: event2,
                            evented_record: ineligible_to_eligible_request_issue)
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
          "ineligible_to_eligible_issues": [
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
              "ineligible_reason": nil,
              "unidentified_issue_text": "An unidentified issue added during the edit",
              "nonrating_issue_category": "Military Retired Pay UPDATED",
              "nonrating_issue_description": "UPDATED TESTING",
              "closed_at": nil,
              "closed_status": nil,
              "contested_rating_issue_diagnostic_code": nil,
              "rating_issue_associated_at": nil,
              "ramp_claim_id": nil,
              "is_unidentified": true,
              "nonrating_issue_bgs_source": nil
            }
          ],
          "eligible_to_ineligible_issues": [],
          "ineligible_to_ineligible_issues": []
        }
      end

      let!(:valid_params) do
        json_test_payload
      end

      context "ineligible_to_eligible updates issue" do
        before do
          request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        end

        it "returns success response whith eligible request_issue" do
          request.headers["Authorization"] = "Token token=#{api_key.key_string}"
          expect(ineligible_to_eligible_request_issue.reference_id).to eq("1234")
          expect(ineligible_to_eligible_request_issue.ineligible_reason).to eq("appeal_to_appeal")
          expect(ineligible_to_eligible_request_issue.contested_issue_description).to eq("original description")
          expect(ineligible_to_eligible_request_issue.nonrating_issue_category).to eq("original category")
          expect(ineligible_to_eligible_request_issue.nonrating_issue_description)
            .to eq("original nonrating description")
          expect(ineligible_to_eligible_request_issue.closed_at).to be_within(100.seconds).of(DateTime.now)
          expect(ineligible_to_eligible_request_issue.closed_status).to eq("ineligible")
          expect(ineligible_to_eligible_request_issue.contention_removed_at).to be_within(1.second).of(DateTime.now)
          expect(ineligible_to_eligible_request_issue.contention_reference_id).to eq(100_500)
          post :decision_review_updated, params: valid_params
          expect(response).to have_http_status(:created)
          expect(response.body).to include("DecisionReviewUpdatedEvent successfully processed")
          ineligible_to_eligible_request_issue.reload
          expect(ineligible_to_eligible_request_issue.event_records.count).to eq(2)
          expect(ineligible_to_eligible_request_issue.ineligible_reason).to eq(nil)
          expect(ineligible_to_eligible_request_issue.contested_issue_description).to eq("UPDATED DESCRIPTION")
          expect(ineligible_to_eligible_request_issue.nonrating_issue_category).to eq("Military Retired Pay UPDATED")
          expect(ineligible_to_eligible_request_issue.nonrating_issue_description).to eq("UPDATED TESTING")
          # expect(ineligible_to_eligible_request_issue.closed_at).to eq(nil)
          expect(ineligible_to_eligible_request_issue.closed_status).to eq(nil)
          expect(ineligible_to_eligible_request_issue.contention_removed_at).to eq(nil)
          expect(ineligible_to_eligible_request_issue.contention_reference_id).to eq(123_456)
        end
      end
    end
  end

  context "tests processing eligible_to_ineligible request issues" do
    describe "POST #decision_review_updated" do
      let!(:eligible_to_ineligible_request_issue) do
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
              "ineligible_reason": "appeal_to_appeal",
              "unidentified_issue_text": "An unidentified issue added during the edit",
              "nonrating_issue_category": "Military Retired Pay ELIGIBLE",
              "nonrating_issue_description": "UPDATED ELIGIBLE",
              "closed_at": 1_702_000_145_000,
              "closed_status": "ineligible",
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

      context "eligible_to_ineligible updates issue" do
        before do
          request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        end

        it "returns success response whith ineligible request_issue" do
          request.headers["Authorization"] = "Token token=#{api_key.key_string}"
          expect(eligible_to_ineligible_request_issue.ineligible_reason).to eq(nil)
          expect(eligible_to_ineligible_request_issue.contested_issue_description).to eq(nil)
          expect(eligible_to_ineligible_request_issue.nonrating_issue_category).to eq(nil)
          expect(eligible_to_ineligible_request_issue.closed_at).to eq(nil)
          expect(eligible_to_ineligible_request_issue.nonrating_issue_description).to eq(nil)
          expect(eligible_to_ineligible_request_issue.closed_status).to eq(nil)
          expect(eligible_to_ineligible_request_issue.reference_id).to eq("1234")
          post :decision_review_updated, params: valid_params
          expect(response).to have_http_status(:created)
          expect(response.body).to include("DecisionReviewUpdatedEvent successfully processed")
          eligible_to_ineligible_request_issue.reload
          expect(eligible_to_ineligible_request_issue.ineligible_reason).to eq("appeal_to_appeal")
          expect(eligible_to_ineligible_request_issue.contested_issue_description).to eq("Eligible UPDATED")
          expect(eligible_to_ineligible_request_issue.nonrating_issue_category).to eq("Military Retired Pay ELIGIBLE")
          expect(eligible_to_ineligible_request_issue.nonrating_issue_description).to eq("UPDATED ELIGIBLE")
          expect(eligible_to_ineligible_request_issue.closed_at).to eq("2023-12-07 20:49:05.000000000 -0500")
        end
      end
    end
  end

  context "tests processing ineligible_to_ineligible request issues" do
    describe "POST #decision_review_updated" do
      let!(:ineligible_to_ineligible_request_issue) do
        create(:request_issue,
               decision_review: review, reference_id: "1234", closed_status: "ineligible", closed_at: DateTime.now,
               ineligible_reason: "appeal_to_appeal", contention_removed_at: DateTime.now,
               contested_issue_description: "original description", nonrating_issue_category: "original category",
               nonrating_issue_description: "original nonrating description", contention_reference_id: 100_500)
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
          "eligible_to_ineligible_issues": [],
          "ineligible_to_ineligible_issues": [
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
              "contested_issue_description": "UPDATED contested issue deascription",
              "contested_rating_issue_profile_date": nil,
              "decision_date": nil,
              "ineligible_due_to_id": nil,
              "ineligible_reason": "appeal_to_appeal",
              "unidentified_issue_text": "An unidentified issue added during the edit",
              "nonrating_issue_category": "UPDATED category",
              "nonrating_issue_description": "UPDATED ELIGIBLE",
              "closed_at": 1_702_000_145_000,
              "closed_status": "ineligible",
              "contested_rating_issue_diagnostic_code": nil,
              "rating_issue_associated_at": nil,
              "ramp_claim_id": nil,
              "is_unidentified": true,
              "nonrating_issue_bgs_source": nil
            }
          ]
        }
      end

      let!(:valid_params) do
        json_test_payload
      end

      context "ineligible_to_ineligible updates issue" do
        before do
          request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        end

        it "returns success response whith updated ineligible request_issue" do
          request.headers["Authorization"] = "Token token=#{api_key.key_string}"
          expect(ineligible_to_ineligible_request_issue.ineligible_reason).to eq("appeal_to_appeal")
          expect(ineligible_to_ineligible_request_issue.contested_issue_description).to eq("original description")
          expect(ineligible_to_ineligible_request_issue.nonrating_issue_category).to eq("original category")
          expect(ineligible_to_ineligible_request_issue.closed_at).to be_within(100.seconds).of(DateTime.now)
          expect(ineligible_to_ineligible_request_issue.nonrating_issue_description)
            .to eq("original nonrating description")
          expect(ineligible_to_ineligible_request_issue.closed_status).to eq("ineligible")
          expect(ineligible_to_ineligible_request_issue.reference_id).to eq("1234")
          post :decision_review_updated, params: valid_params
          expect(response).to have_http_status(:created)
          expect(response.body).to include("DecisionReviewUpdatedEvent successfully processed")
          ineligible_to_ineligible_request_issue.reload
          expect(ineligible_to_ineligible_request_issue.ineligible_reason).to eq("appeal_to_appeal")
          expect(ineligible_to_ineligible_request_issue.contested_issue_description)
            .to eq("UPDATED contested issue deascription")
          expect(ineligible_to_ineligible_request_issue.nonrating_issue_category).to eq("UPDATED category")
          expect(ineligible_to_ineligible_request_issue.nonrating_issue_description).to eq("UPDATED ELIGIBLE")
          expect(ineligible_to_ineligible_request_issue.closed_at).to eq("2023-12-07 20:49:05.000000000 -0500")
        end
      end
    end
  end
end
