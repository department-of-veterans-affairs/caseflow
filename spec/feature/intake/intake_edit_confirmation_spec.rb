require "rails_helper"
require "support/intake_helpers"

RSpec.feature "Intake Edit Confirmation", focus: true do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)
    FeatureToggle.enable!(:intake_legacy_opt_in)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 26))

    # skip the sync call since all edit requests require resyncing
    # currently, we're not mocking out vbms and bgs
    allow_any_instance_of(EndProductEstablishment).to receive(:sync!).and_return(nil)
  end

  after do
    FeatureToggle.disable!(:intakeAma)
    FeatureToggle.disable!(:intake_legacy_opt_in)
  end

  let(:veteran) do
    create(:veteran,
           first_name: "Ed",
           last_name: "Merica")
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:receipt_date) { Time.zone.today - 20 }
  let(:profile_date) { "2017-11-02T07:00:00.000Z" }

  # Requirements to implement for both HLR and SC
  describe "given a HLR" do
    let(:higher_level_review) do
      HigherLevelReview.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        informal_conference: false,
        same_office: false,
        benefit_type: "compensation",
        veteran_is_not_claimant: false
      )
    end

    let(:intake) do
      Intake.create!(
        user_id: current_user.id,
        detail: higher_level_review,
        veteran_file_number: veteran.file_number,
        started_at: Time.zone.now,
        completed_at: Time.zone.now,
        completion_status: "success",
        type: "HigherLevelReviewIntake"
      )
    end

    let(:existing_request_rating_issue) do
      create(:request_issue,
             review_request: higher_level_review,
             rating_issue_reference_id: "def456",
             rating_issue_profile_date: profile_date,
             description: "PTSD denied",
             contention_reference_id: "4567")
    end

    before do
      higher_level_review.create_issues!([existing_request_rating_issue])
      higher_level_review.process_end_product_establishments!
    end

    it "confirms that an EP is established", focus: true do
      visit "higher_level_reviews/#{get_claim_id(higher_level_review)}/edit"
      click_intake_add_issue
      add_intake_nonrating_issue

      click_edit_submit

      expect(page).to have_current_path(
        "/higher_level_reviews/#{get_claim_id(higher_level_review)}/edit/confirmation"
      )
      expect(page).to have_content("A Higher-Level Review Nonrating EP is being established")
    end

    it "shows when an EP is being canceled" do
      visit "higher_level_reviews/#{get_claim_id(higher_level_review)}/edit"
      click_intake_add_issue
      remove_intake_rating_issue

      click_edit_submit

      expect(page).to have_current_path(
        "/higher_level_reviews/#{get_claim_id(higher_level_review)}/edit/confirmation"
      )
      expect(page).to have_content("A Higher-Level Review Rating EP is being canceled")
    end

    it "shows when an EP is being updated" do
      visit "higher_level_reviews/#{get_claim_id(higher_level_review)}/edit"
      click_intake_add_issue
      add_intake_rating_issue

      click_edit_submit

      expect(page).to have_current_path(
        "/higher_level_reviews/#{get_claim_id(higher_level_review)}/edit/confirmation"
      )
      expect(page).to have_content("Contentions on Higher-Level Review Rating EP are being updated")
    end

    it "includes a warning about unidentified issues" do
      visit "higher_level_reviews/#{get_claim_id(higher_level_review)}/edit"
      click_intake_add_issue
      add_unidentified_issue

      click_edit_submit

      expect(page).to have_current_path(
        "/higher_level_reviews/#{get_claim_id(higher_level_review)}/edit/confirmation"
      )
      expect(page).to have_content("There is still an unidentified issue")
    end
  end
end
