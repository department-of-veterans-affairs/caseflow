# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewUpdatedController, type: :controller do
  describe "POST #decision_review_updated added 1 issue" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
    let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 12_345_678) }
    let(:review) { epe.source }

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

    context "adds 1 issue" do
      before do
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
      end

      it "returns success response whith 1 added issue" do
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        expect(review.request_issues.find_by(reference_id: "1234")).to be(nil)
        expect(review.request_issues.size).to eq(0)
        post :decision_review_updated, params: valid_params
        review.reload
        expect(response).to have_http_status(:ok)
        expect(review.request_issues.size).to eq(1)
        new_issue = review.request_issues.find_by(reference_id: "1234")
        expect(new_issue).to_not eq(nil)
        expect(new_issue.contested_issue_description).to eq("some_description")
        expect(new_issue.type).to eq("RequestIssue")
        expect(response.body).to include("DecisionReviewUpdatedEvent successfully processed")
        expect(new_issue.created_at).to be_within(100.seconds).of(DateTime.now)
        expect(new_issue.updated_at).to be_within(100.seconds).of(DateTime.now)
        expect(new_issue.any_updates?).to eq(true)
      end
    end
  end

  describe "POST #decision_review_updated added 2 issues" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
    let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 12_345_678) }
    let(:review) { epe.source }
    let!(:existing_issue) do
      create(:request_issue,
             decision_review: review, reference_id: "1234", closed_status: nil, closed_at: nil,
             contention_removed_at: nil,
             contested_issue_description: "existed_issue_description", contention_reference_id: 100_500)
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
        "added_issues": [
          {
            "original_caseflow_request_issue_id": nil,
            "contested_rating_decision_reference_id": nil,
            "contested_rating_issue_reference_id": nil,
            "contested_decision_issue_id": nil,
            "untimely_exemption": false,
            "untimely_exemption_notes": "2some notes2",
            "edited_description": nil,
            "vacols_id": "2some_id2",
            "vacols_sequence_id": "2some_sequence_id2",
            "nonrating_issue_bgs_id": "some_bgs_id",
            "type": "RequestIssue",
            "decision_review_issue_id": 2234,
            "contention_reference_id": 123_456,
            "benefit_type": "compensation",
            "contested_issue_description": "2some_description2",
            "contested_rating_issue_profile_date": "1222555",
            "decision_date": 18_568,
            "ineligible_due_to_id": nil,
            "ineligible_reason": nil,
            "unidentified_issue_text": "2An unidentified issue added during the edit2",
            "nonrating_issue_category": nil,
            "nonrating_issue_description": nil,
            "closed_at": nil,
            "closed_status": nil,
            "contested_rating_issue_diagnostic_code": "9421",
            "rating_issue_associated_at": nil,
            "ramp_claim_id": nil,
            "is_unidentified": true,
            "nonrating_issue_bgs_source": nil
          },
          {
            "original_caseflow_request_issue_id": nil,
            "contested_rating_decision_reference_id": nil,
            "contested_rating_issue_reference_id": nil,
            "contested_decision_issue_id": nil,
            "untimely_exemption": false,
            "untimely_exemption_notes": "3some notes3",
            "edited_description": nil,
            "vacols_id": "3some_id3",
            "vacols_sequence_id": "3some_sequence_id3",
            "nonrating_issue_bgs_id": "3some_bgs_id3",
            "type": "RequestIssue",
            "decision_review_issue_id": 3234,
            "contention_reference_id": 123_456,
            "benefit_type": "compensation",
            "contested_issue_description": "3some_description3",
            "contested_rating_issue_profile_date": "122253",
            "decision_date": 17_568,
            "ineligible_due_to_id": nil,
            "ineligible_reason": nil,
            "unidentified_issue_text": "3An unidentified issue added during the edit3",
            "nonrating_issue_category": nil,
            "nonrating_issue_description": nil,
            "closed_at": nil,
            "closed_status": nil,
            "contested_rating_issue_diagnostic_code": "9413",
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

    context "adds 1 issue" do
      before do
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
      end

      it "returns success response whith 2 added issues" do
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        expect(review.request_issues.find_by(reference_id: "1234")).to_not be(nil)
        expect(review.request_issues.size).to eq(1)
        new_issue1 = review.request_issues.find_by(reference_id: "1234")
        expect(new_issue1.contested_issue_description).to eq("existed_issue_description")
        expect(new_issue1.type).to eq("RequestIssue")
        expect(new_issue1.created_at).to be_within(100.seconds).of(DateTime.now)
        expect(new_issue1.updated_at).to be_within(100.seconds).of(DateTime.now)
        post :decision_review_updated, params: valid_params
        expect(response).to have_http_status(:ok)
        review.reload
        expect(review.request_issues.size).to eq(3)
        new_issue2 = review.request_issues.find_by(reference_id: "2234")
        expect(new_issue2).to_not eq(nil)
        expect(new_issue2.contested_issue_description).to eq("2some_description2")
        expect(new_issue2.type).to eq("RequestIssue")
        expect(response.body).to include("DecisionReviewUpdatedEvent successfully processed")
        expect(new_issue2.created_at).to be_within(100.seconds).of(DateTime.now)
        expect(new_issue2.updated_at).to be_within(100.seconds).of(DateTime.now)
        expect(new_issue2.any_updates?).to eq(true)
        new_issue3 = review.request_issues.find_by(reference_id: "3234")
        expect(new_issue3).to_not eq(nil)
        expect(new_issue3.contested_issue_description).to eq("3some_description3")
        expect(new_issue3.type).to eq("RequestIssue")
        expect(response.body).to include("DecisionReviewUpdatedEvent successfully processed")
        expect(new_issue3.created_at).to be_within(100.seconds).of(DateTime.now)
        expect(new_issue3.updated_at).to be_within(100.seconds).of(DateTime.now)
        expect(new_issue3.any_updates?).to eq(true)
      end
    end
  end
end
