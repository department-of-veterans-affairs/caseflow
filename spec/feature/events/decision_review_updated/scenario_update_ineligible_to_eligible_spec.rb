# frozen_string_literal: true

require "rails_helper"

RSpec.feature "DecisionReviewUpdated", type: :feature do
  let!(:current_user) { User.authenticate! }
  let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
  let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 12_345_678) }
  let(:review) { epe.source }

  let!(:ineligible_to_eligible_request_issue) do
    create(:request_issue,
           decision_review: review, reference_id: "1234", closed_status: "ineligible", closed_at: DateTime.now,
           ineligible_reason: "untimely", contention_removed_at: DateTime.now, decision_date: Time.zone.yesterday,
           contested_issue_description: "original description", nonrating_issue_category: "original category",
           nonrating_issue_description: "original nonrating description", contention_reference_id: 100_500)
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:json_test_payload) do
    {
      "event_id": 214_786,
      "claim_id": 12_345_678,
      "css_id": "BVADWISE101",
      "detail_type": "HigherLevelReview",
      "station": "101",
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
          "nonrating_issue_bgs_source": nil,
          "end_product_establishment_id": epe.id
        }
      ],
      "eligible_to_ineligible_issues": [],
      "ineligible_to_ineligible_issues": []
    }
  end

  let!(:eligible_request_issue) do
    create(
      :request_issue,
      decision_review: review,
      nonrating_issue_category: "Military Retired Pay",
      nonrating_issue_description: "eligible nonrating description",
      ineligible_reason: nil,
      benefit_type: "compensation",
      decision_date: Time.zone.today
    )
  end

  context "ineligible_to_eligible updates issue" do
    before do
      allow_any_instance_of(HigherLevelReview).to receive(:validate_prior_to_edit).and_return(true)
      consumer_event_id = json_test_payload[:event_id]
      claim_id = json_test_payload[:claim_id]
      headers = { "Authorization" => "Token token=#{api_key.key_string}" }
      consumer_and_claim_ids = { consumer_event_id: consumer_event_id, reference_id: claim_id }
      Events::DecisionReviewUpdated.update!(consumer_and_claim_ids, headers, json_test_payload)
      review.create_claimant!(participant_id: 123, payee_code: "10", type: "DependentClaimant")
      review.reload.create_issues!([eligible_request_issue, ineligible_to_eligible_request_issue])
      review.establish!
    end

    it "able to render edit page without error after updating ineligible to eligible" do
      visit "search"
      fill_in "searchBarEmptyList", with: review.veteran_file_number
      click_on "Search"
      expect(page).to have_content("Ready for decision")
      # Appellant Name
      expect(page).to have_content("Tom Brady")
      visit "higher_level_reviews/#{epe.reference_id}/edit"
      expect(page).to have_content("Tom Brady, Spouse (payee code 10)")
      expect(page).to have_content("DIC: Service connection denied (UPDATED)")
      expect(page).to have_content("Higher-Level Review Non-Rating")
      expect(page).to have_no_content("Something went wrong")
    end
  end
end
