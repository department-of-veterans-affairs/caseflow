require "rails_helper"
require "support/intake_helpers"

RSpec.feature "Intake Edit Confirmation" do
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
  let(:some_timely_date_before_receipt_date) { (receipt_date - 3.months).strftime("%m/%d/%Y") }
  let(:profile_date) { "2017-11-02T07:00:00.000Z" }

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date,
      profile_date: profile_date,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" }
      ]
    )
  end

  # Requirements to implement for both HLR and SC
  describe "given a HLR" do
    let!(:higher_level_review) do
      HigherLevelReview.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        informal_conference: false,
        same_office: false,
        benefit_type: "compensation",
        veteran_is_not_claimant: true
      )
    end

    # create associated intake
    let!(:intake) do
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

    let!(:request_issue) do
      create(:request_issue,
             rating_issue_reference_id: "def456",
             rating_issue_profile_date: rating.profile_date,
             review_request: higher_level_review,
             description: "PTSD denied")
    end

    let(:request_issues) { [request_issue] }

    let(:rating_ep_claim_id) do
      EndProductEstablishment.find_by(
        source: higher_level_review,
        code: "030HLRR"
      ).reference_id
    end

    before do
      higher_level_review.create_claimants!(participant_id: "5382910292", payee_code: "10")
      allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
        first_name: "BOB",
        last_name: "VANCE",
        ptcpnt_id: "5382910292",
        relationship_type: "Spouse"
      )
      higher_level_review.create_issues!(request_issues)
      higher_level_review.establish!
    end

    it "confirms that an EP is established" do
      visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(date: some_timely_date_before_receipt_date)
      click_edit_submit
      click_number_of_issues_changed_confirmation

      expect(page).to have_current_path(
        "/higher_level_reviews/#{get_claim_id(higher_level_review)}/edit/confirmation"
      )
      expect(page).to have_content("A Higher-Level Review Nonrating EP is being established")
    end

    it "shows when an EP is being canceled" do
      visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
      # first add a nonrating issue so we can remove the rating issue & EP
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(date: some_timely_date_before_receipt_date)
      click_remove_intake_issue(1)
      click_remove_issue_confirmation
      click_edit_submit

      expect(page).to have_current_path(
        "/higher_level_reviews/#{rating_ep_claim_id}/edit/confirmation"
      )
      expect(page).to have_content("A Higher-Level Review Rating EP is being canceled")
    end

    it "shows when an EP is being updated" do
      visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")
      click_edit_submit
      click_number_of_issues_changed_confirmation

      expect(page).to have_current_path(
        "/higher_level_reviews/#{rating_ep_claim_id}/edit/confirmation"
      )
      expect(page).to have_content("Contentions on Higher-Level Review Rating EP are being updated")
    end

    it "includes a warning about unidentified issues" do
      visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
      click_intake_add_issue
      add_intake_unidentified_issue
      click_edit_submit
      click_still_have_unidentified_issue_confirmation
      click_number_of_issues_changed_confirmation

      expect(page).to have_current_path(
        "/higher_level_reviews/#{rating_ep_claim_id}/edit/confirmation"
      )
      expect(page).to have_content("There is still an unidentified issue")
    end
  end
end
