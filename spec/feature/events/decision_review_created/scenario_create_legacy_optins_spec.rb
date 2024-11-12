# frozen_string_literal: true

# rubocop:disable Style/NumericLiterals

RSpec.describe Api::Events::V1::DecisionReviewCreatedController, type: :controller do
  describe "POST #decision_review_created" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
    let!(:person) do
      Person.create(participant_id: "1826209", first_name: "Jimmy", last_name: "Longstocks",
                    middle_name: "Goob", ssn: "989773212", name_suffix: "")
    end
    let!(:vacols_issue1) { create(:case_issue, issseq: 1) }
    let!(:vacols_issue2) { create(:case_issue, issseq: 2) }
    let!(:vacols_issue3) { create(:case_issue, issseq: 3) }
    let!(:vacols_case) do
      create(
        :case,
        :status_active,
        bfcurloc: "77",
        bfkey: "VACOLSTEST",
        case_issues: [
          vacols_issue1,
          vacols_issue2,
          vacols_issue3
        ]
      )
    def json_test_payload
      {
        "event_id": "123",
        "claim_id": "9999",
        "css_id": "BVADWISE",
        "detail_type": "HigherLevelReview",
        "station": "101",
        "intake": {
          "started_at": 1702067143435,
          "completion_started_at": 1702067145000,
          "completed_at": 1702067145000,
          "completion_status": "success",
          "type": "HigherLevelReviewIntake",
          "detail_type": "HigherLevelReview"
        },
        "veteran": {
          "participant_id": "1826209",
          "bgs_last_synced_at": 1708533584000,
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
          "legacy_opt_in_approved": true,
          "receipt_date": 20231208,
          "veteran_is_not_claimant": true,
          "establishment_attempted_at": 1702067145000,
          "establishment_last_submitted_at": 1702067145000,
          "establishment_processed_at": 1702067145000,
          "establishment_submitted_at": 1702067145000,
          "informal_conference": false,
          "same_office": false
        },
        "end_product_establishment": {
          "benefit_type_code": "1",
          "claim_date": 20231208,
          "code": "030HLRNR",
          "modifier": "030",
          "payee_code": "00",
          "reference_id": "337534",
          "limited_poa_access": nil,
          "limited_poa_code": nil,
          "committed_at": 1702067145000,
          "established_at": 1702067145000,
          "last_synced_at": 1702067145000,
          "synced_status": "RW",
          "development_item_reference_id": nil
        },
        "request_issues": [
          {
            "decision_review_issue_id": 1,
            "benefit_type": "compensation",
            "contested_issue_description": nil,
            "contention_reference_id": 7905751,
            "contested_rating_decision_reference_id": nil,
            "contested_rating_issue_profile_date": nil,
            "contested_rating_issue_reference_id": nil,
            "contested_decision_issue_id": nil,
            "decision_date": 20231220,
            "ineligible_due_to_id": nil,
            "ineligible_reason": nil,
            "is_unidentified": false,
            "unidentified_issue_text": nil,
            "nonrating_issue_category": "Accrued Benefits",
            "nonrating_issue_description": "The user entered description if the issue is a nonrating issue",
            "untimely_exemption": nil,
            "untimely_exemption_notes": nil,
            "vacols_id": nil,
            "vacols_sequence_id": nil,
            "closed_at": nil,
            "closed_status": nil,
            "contested_rating_issue_diagnostic_code": nil,
            "ramp_claim_id": nil,
            "rating_issue_associated_at": nil,
            "nonrating_issue_bgs_id": "13",
            "nonrating_issue_bgs_source": "Test Source"
          },
          {
            "decision_review_issue_id": 2,
            "benefit_type": "compensation",
            "contested_issue_description": nil,
            "contention_reference_id": 7905752,
            "contested_rating_decision_reference_id": nil,
            "contested_rating_issue_profile_date": nil,
            "contested_rating_issue_reference_id": nil,
            "contested_decision_issue_id": nil,
            "decision_date": 20231220,
            "ineligible_due_to_id": nil,
            "ineligible_reason": nil,
            "is_unidentified": false,
            "unidentified_issue_text": nil,
            "nonrating_issue_category": "Accrued Benefits",
            "nonrating_issue_description": "The user entered description if the issue is a nonrating issue",
            "untimely_exemption": nil,
            "untimely_exemption_notes": nil,
            "vacols_id": "VACOLSTEST",
            "vacols_sequence_id": 1,
            "closed_at": nil,
            "closed_status": nil,
            "contested_rating_issue_diagnostic_code": nil,
            "ramp_claim_id": nil,
            "rating_issue_associated_at": nil,
            "nonrating_issue_bgs_id": "13",
            "nonrating_issue_bgs_source": "Test Source"
          },
          {
            "decision_review_issue_id": 3,
            "benefit_type": "compensation",
            "contested_issue_description": nil,
            "contention_reference_id": 7905753,
            "contested_rating_decision_reference_id": nil,
            "contested_rating_issue_profile_date": nil,
            "contested_rating_issue_reference_id": nil,
            "contested_decision_issue_id": nil,
            "decision_date": 20231220,
            "ineligible_due_to_id": nil,
            "ineligible_reason": nil,
            "is_unidentified": false,
            "unidentified_issue_text": nil,
            "nonrating_issue_category": "Accrued Benefits",
            "nonrating_issue_description": "The user entered description if the issue is a nonrating issue",
            "untimely_exemption": nil,
            "untimely_exemption_notes": nil,
            "vacols_id": "VACOLSTEST",
            "vacols_sequence_id": 2,
            "closed_at": nil,
            "closed_status": nil,
            "contested_rating_issue_diagnostic_code": nil,
            "ramp_claim_id": nil,
            "rating_issue_associated_at": nil,
            "nonrating_issue_bgs_id": "13",
            "nonrating_issue_bgs_source": "Test Source"
          },
          {
            "decision_review_issue_id": 4,
            "benefit_type": "compensation",
            "contested_issue_description": nil,
            "contention_reference_id": 7905754,
            "contested_rating_decision_reference_id": nil,
            "contested_rating_issue_profile_date": nil,
            "contested_rating_issue_reference_id": nil,
            "contested_decision_issue_id": nil,
            "decision_date": 20231220,
            "ineligible_due_to_id": nil,
            "ineligible_reason": "legacy_appeal_not_eligible",
            "is_unidentified": false,
            "unidentified_issue_text": nil,
            "nonrating_issue_category": "Accrued Benefits",
            "nonrating_issue_description": "The user entered description if the issue is a nonrating issue",
            "untimely_exemption": nil,
            "untimely_exemption_notes": nil,
            "vacols_id": "VACOLSTEST",
            "vacols_sequence_id": 3,
            "closed_at": nil,
            "closed_status": nil,
            "contested_rating_issue_diagnostic_code": nil,
            "ramp_claim_id": nil,
            "rating_issue_associated_at": nil,
            "nonrating_issue_bgs_id": "13",
            "nonrating_issue_bgs_source": "Test Source"
          }
        ]
      }
    end

    let!(:valid_params) do
      json_test_payload
    end

    context "with a valid payload" do
      it "creates appropriate Request Issue and Legacy Issue (plus Optins) data" do
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        request.headers["X-VA-Vet-SSN"] = "123456789"
        request.headers["X-VA-File-Number"] = "77799777"
        request.headers["X-VA-Vet-First-Name"] = "John"
        request.headers["X-VA-Vet-Last-Name"] = "Smith"
        request.headers["X-VA-Vet-Middle-Name"] = "Alexander"
        request.headers["X-VA-Claimant-DOB"] = DateTime.now - 30.years
        request.headers["X-VA-Claimant-Email"] = "jim@google.com"
        request.headers["X-VA-Claimant-First-Name"] = "Jimmy"
        request.headers["X-VA-Claimant-Last-Name"] = "Longstocks"
        request.headers["X-VA-Claimant-Middle-Name"] = "Goob"
        request.headers["X-VA-Claimant-SSN"] = "989773212"
        post :decision_review_created, params: valid_params
        expect(response).to have_http_status(:created)

        expect(RequestIssue.count).to eq(4)
        expect(RequestIssue.last.ineligible_reason).to eq("legacy_appeal_not_eligible")
        expect(LegacyIssue.count).to eq(3)
        # The last issue in the payload should NOT create an Optin because it's ineligible
        expect(LegacyIssueOptin.count).to eq(2)
      end
    end
  end
end
