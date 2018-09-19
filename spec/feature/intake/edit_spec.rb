require "rails_helper"

RSpec.feature "Edit issues" do
  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)
    FeatureToggle.enable!(:test_facols)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 26))
  end

  after do
    FeatureToggle.disable!(:intakeAma)
    FeatureToggle.disable!(:test_facols)
  end

  let(:veteran) do
    Generators::Veteran.build(file_number: "12341234", first_name: "Ed", last_name: "Merica")
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:receipt_date) { Time.zone.today - 20 }

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date + 1.day,
      profile_date: receipt_date + 4.days,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" }
      ]
    )
  end

  context "Higher Level Reviews" do
    let!(:higher_level_review) do
      HigherLevelReview.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        informal_conference: false,
        same_office: false
      )
    end

    let!(:request_issue) do
      RequestIssue.create!(
        rating_issue_reference_id: "abc123",
        rating_issue_profile_date: rating.profile_date,
        review_request: higher_level_review,
        description: "Left knee granted"
      )
    end

    before do
      higher_level_review.create_issues!([request_issue])
      higher_level_review.process_end_product_establishments!
    end

    it "shows selected issues" do
      visit "higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit/select_issues"
      expect(find_field("PTSD denied", visible: false)).to_not be_checked
      expect(find_field("Left knee granted", visible: false)).to be_checked
    end

    it "enables save button only when dirty" do
      visit "higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit/select_issues"
      expect(page).to have_button("Save", disabled: true)

      find("label", text: "PTSD denied").click
      expect(find_field("PTSD denied", visible: false)).to be_checked
      expect(page).to have_button("Save", disabled: false)

      find("label", text: "PTSD denied").click
      expect(find_field("PTSD denied", visible: false)).to_not be_checked
      expect(page).to have_button("Save", disabled: true)
    end

    it "shows an error message if no issues are selected" do
      visit "higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit/select_issues"
      find("label", text: "Left knee granted").click
      expect(find_field("Left knee granted", visible: false)).to_not be_checked

      safe_click("#button-submit-update")

      expect(page).to have_content("No issues were selected")
    end

    it "updates selected issues" do
      visit "higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit/select_issues"

      find("label", text: "Left knee granted").click
      find("label", text: "PTSD denied").click
      expect(page).to have_button("Save", disabled: false)

      safe_click("#button-submit-update")
      # update happens, on success the button should be disabled again as state matches server
      expect(page).to have_button("Save", disabled: true)

      # reload to verify that the new issues populate the form
      visit current_path
      expect(find_field("PTSD denied", visible: false)).to be_checked
      expect(find_field("Left knee granted", visible: false)).to_not be_checked

      # assert server has updated data
      expect(higher_level_review.reload.request_issues.first.description).to eq("PTSD denied")
      expect(request_issue.reload.review_request_id).to be_nil
      # expect contentions to reflect issue update
    end

    feature "cancel edits" do
      def click_cancel(visit_page)
        visit "higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit#{visit_page}"
        click_on "Cancel edit"
        correct_path = "/higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit/cancel"
        expect(page).to have_current_path(correct_path)
        expect(page).to have_content("Claim Edit Cancelled")
      end

      scenario "from landing page" do
        click_cancel("/")
      end

      scenario "from select_issues page" do
        click_cancel("/select_issues")
      end
    end
  end

  context "Supplemental claims" do
    let!(:supplemental_claim) do
      SupplementalClaim.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date
      )
    end

    let!(:request_issue) do
      RequestIssue.create!(
        rating_issue_reference_id: "abc123",
        rating_issue_profile_date: rating.profile_date,
        review_request: supplemental_claim,
        description: "Left knee granted"
      )
    end

    before do
      supplemental_claim.create_issues!([request_issue])
      supplemental_claim.process_end_product_establishments!
    end

    it "shows selected issues" do
      visit "supplemental_claims/#{supplemental_claim.end_product_claim_id}/edit/select_issues"
      expect(find_field("PTSD denied", visible: false)).to_not be_checked
      expect(find_field("Left knee granted", visible: false)).to be_checked
    end

    it "enables save button only when dirty" do
      visit "supplemental_claims/#{supplemental_claim.end_product_claim_id}/edit/select_issues"
      expect(page).to have_button("Save", disabled: true)

      find("label", text: "PTSD denied").click
      expect(find_field("PTSD denied", visible: false)).to be_checked
      expect(page).to have_button("Save", disabled: false)

      find("label", text: "PTSD denied").click
      expect(find_field("PTSD denied", visible: false)).to_not be_checked
      expect(page).to have_button("Save", disabled: true)
    end

    it "shows an error message if no issues are selected" do
      visit "supplemental_claims/#{supplemental_claim.end_product_claim_id}/edit/select_issues"
      find("label", text: "Left knee granted").click
      expect(find_field("Left knee granted", visible: false)).to_not be_checked

      safe_click("#button-submit-update")

      expect(page).to have_content("No issues were selected")
    end

    it "updates selected issues" do
      visit "supplemental_claims/#{supplemental_claim.end_product_claim_id}/edit/select_issues"

      find("label", text: "Left knee granted").click
      find("label", text: "PTSD denied").click
      expect(page).to have_button("Save", disabled: false)

      safe_click("#button-submit-update")
      # update happens, on success the button should be disabled again as state matches server
      expect(page).to have_button("Save", disabled: true)

      # reload to verify that the new issues populate the form
      visit current_path
      expect(find_field("PTSD denied", visible: false)).to be_checked
      expect(find_field("Left knee granted", visible: false)).to_not be_checked

      # assert server has updated data
      expect(supplemental_claim.reload.request_issues.first.description).to eq("PTSD denied")
      expect(request_issue.reload.review_request_id).to be_nil
      # expect contentions to reflect issue update
    end

    feature "cancel edits" do
      def click_cancel(visit_page)
        visit "supplemental_claims/#{supplemental_claim.end_product_claim_id}/edit#{visit_page}"
        click_on "Cancel edit"
        correct_path = "/supplemental_claims/#{supplemental_claim.end_product_claim_id}/edit/cancel"
        expect(page).to have_current_path(correct_path)
        expect(page).to have_content("Claim Edit Cancelled")
      end

      scenario "from landing page" do
        click_cancel("/")
      end

      scenario "from select_issues page" do
        click_cancel("/select_issues")
      end
    end
  end
end
