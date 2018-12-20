require "rails_helper"
require "support/intake_helpers"

RSpec.feature "Intake Edit Confirmation" do
  include IntakeHelpers

  before { setup_intake_flags }
  after { teardown_intake_flags }

  let!(:current_user) { User.authenticate!(roles: ["Mail Intake"]) }
  let!(:intake) { create(:intake, :completed, detail: decision_review, user_id: current_user.id) }

  describe "given a HLR with a rating request issue" do
    let(:decision_review) do
      create(:higher_level_review, veteran_file_number: create(:veteran).file_number)
    end

    let(:rating) do
      Generators::Rating.build(
        participant_id: decision_review.veteran.participant_id,
        promulgation_date: decision_review.receipt_date,
        issues: [
          { reference_id: "abc123", decision_text: "Left knee granted" },
          { reference_id: "def456", decision_text: "PTSD denied" }
        ]
      )
    end

    let(:request_issue) do
      create(:request_issue,
             rating_issue_reference_id: "def456",
             rating_issue_profile_date: rating.profile_date,
             review_request: decision_review,
             description: "PTSD denied")
    end

    before do
      decision_review.create_issues!([request_issue])
      decision_review.establish!
    end

    it "confirms that an EP is being established" do
      visit "higher_level_reviews/#{get_claim_id(decision_review)}/edit"
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(date: (decision_review.receipt_date - 1.month).strftime("%m/%d/%Y"))
      click_edit_submit
      click_number_of_issues_changed_confirmation

      expect(page).to have_current_path(
        "/higher_level_reviews/#{get_claim_id(decision_review)}/edit/confirmation"
      )
      expect(page).to have_content("A Higher-Level Review Nonrating EP is being established")
    end

    it "shows when an EP is being canceled" do
      visit "higher_level_reviews/#{get_claim_id(decision_review)}/edit"
      # first add a nonrating issue so we can remove the rating issue & EP
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(date: (decision_review.receipt_date - 1.month).strftime("%m/%d/%Y"))
      click_remove_intake_issue(1)
      click_remove_issue_confirmation
      click_edit_submit

      expect(page).to have_current_path(
        "/higher_level_reviews/#{get_claim_id(decision_review)}/edit/confirmation"
      )
      expect(page).to have_content("A Higher-Level Review Rating EP is being canceled")
    end

    it "shows when an EP is being updated" do
      visit "higher_level_reviews/#{get_claim_id(decision_review)}/edit"
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")
      click_edit_submit
      click_number_of_issues_changed_confirmation

      expect(page).to have_current_path(
        "/higher_level_reviews/#{get_claim_id(decision_review)}/edit/confirmation"
      )
      expect(page).to have_content("Contentions on Higher-Level Review Rating EP are being updated")
    end

    it "includes warnings about unidentified issues" do
      visit "higher_level_reviews/#{get_claim_id(decision_review)}/edit"
      click_intake_add_issue
      add_intake_unidentified_issue
      click_edit_submit
      click_still_have_unidentified_issue_confirmation
      click_number_of_issues_changed_confirmation

      expect(page).to have_current_path(
        "/higher_level_reviews/#{get_claim_id(decision_review)}/edit/confirmation"
      )
      expect(page).to have_content("There is still an unidentified issue")
    end
  end
end
