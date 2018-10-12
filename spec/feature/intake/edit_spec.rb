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
  let(:profile_date) { "2017-05-02T07:00:00.000Z" }

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date + 1.day,
      profile_date: profile_date,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" }
      ]
    )
  end

  def check_row(label, text)
    row = find("tr", text: label)
    expect(row).to have_text(text)
  end

  context "Higher Level Reviews" do
    let!(:higher_level_review) do
      HigherLevelReview.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        informal_conference: false,
        same_office: false,
        benefit_type: "compensation"
      )
    end

    let!(:request_issue) do
      RequestIssue.create!(
        rating_issue_reference_id: "def456",
        rating_issue_profile_date: rating.profile_date,
        review_request: higher_level_review,
        description: "PTSD denied"
      )
    end

    before do
      higher_level_review.create_issues!([request_issue])
      higher_level_review.process_end_product_establishments!
      higher_level_review.create_claimants!(participant_id: "5382910292", payee_code: "10")

      allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
        first_name: "BOB",
        last_name: "VANCE",
        ptcpnt_id: "5382910292",
        relationship_type: "Spouse"
      )
    end

    it "shows request issues and allows adding/removing issues" do
      visit "higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit"
      # Check that request issues appear correctly as added issues
      expect(page).to_not have_content("Left knee granted")
      expect(page).to have_content("PTSD denied")

      expect(page).to have_content("Add Issues")
      check_row("Form", Constants.INTAKE_FORM_NAMES.higher_level_review)
      check_row("Benefit type", "Compensation")
      check_row("Claimant", "Bob Vance, Spouse (payee code 10)")

      safe_click "#button-add-issue"

      expect(page).to have_content("Add issue 2")
      expect(page).to have_content("Does issue 2 match any of these issues")
      expect(page).to have_content("Left knee granted")
      expect(page).to have_content("PTSD denied")

      # test canceling adding an issue by closing the modal
      safe_click ".close-modal"
      expect(page).to_not have_content("2. Left knee granted")

      # adding an issue should show the issue
      safe_click "#button-add-issue"
      find("label", text: "Left knee granted").click
      safe_click ".add-issue"

      expect(page).to have_content("2. Left knee granted")
      expect(page).to_not have_content("Notes:")
      safe_click ".remove-issue"

      expect(page).not_to have_content("PTSD denied")

      # re-add to proceed
      safe_click "#button-add-issue"
      find("label", text: "PTSD denied").click
      fill_in "Notes", with: "I am an issue note"
      safe_click ".add-issue"
      expect(page).to have_content("2. PTSD denied")
      expect(page).to have_content("I am an issue note")

      # clicking add issue again should show a disabled radio button for that same rating
      safe_click "#button-add-issue"
      expect(page).to have_content("Add issue 3")
      expect(page).to have_content("Does issue 3 match any of these issues")
      expect(page).to have_content("Left knee granted (already selected for issue 1)")
      expect(page).to have_css("input[disabled][id='rating-radio_abc123']", visible: false)

      # Add non-rated issue
      safe_click ".no-matching-issues"
      expect(page).to have_content("Does issue 3 match any of these issue categories?")
      expect(page).to have_button("Add this issue", disabled: true)
      fill_in "Issue category", with: "Active Duty Adjustments"
      find("#issue-category").send_keys :enter
      fill_in "Issue description", with: "Description for Active Duty Adjustments"
      fill_in "Decision date", with: "04/25/2018"
      expect(page).to have_button("Add this issue", disabled: false)
      safe_click ".add-issue"
      expect(page).to have_content("3 issues")

      # add unidentified issue
      safe_click "#button-add-issue"
      safe_click ".no-matching-issues"
      safe_click ".no-matching-issues"
      expect(page).to have_content("Describe the issue to mark it as needing further review.")
      fill_in "Transcribe the issue as it's written on the form", with: "This is an unidentified issue"
      safe_click ".add-issue"
      expect(page).to have_content("4 issues")
      expect(page).to have_content("This is an unidentified issue")
    end

    it "enables save button only when dirty", skip: "save button in future PR" do
      visit "higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit/select_issues"
      expect(page).to have_button("Save", disabled: true)

      find("label", text: "PTSD denied").click
      expect(find_field("PTSD denied", visible: false)).to be_checked
      expect(page).to have_button("Save", disabled: false)

      find("label", text: "PTSD denied").click
      expect(find_field("PTSD denied", visible: false)).to_not be_checked
      expect(page).to have_button("Save", disabled: true)
    end

    it "shows an error message if no issues are selected", skip: "save button in future PR" do
      visit "higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit/select_issues"
      find("label", text: "Left knee granted").click
      expect(find_field("Left knee granted", visible: false)).to_not be_checked

      safe_click("#button-submit-update")

      expect(page).to have_content("No issues were selected")
    end

    scenario "shows error message if an update is in progress", skip: "save button in future PR" do
      RequestIssuesUpdate.create!(
        review: higher_level_review,
        user: current_user,
        before_request_issue_ids: [request_issue.id],
        after_request_issue_ids: [request_issue.id],
        attempted_at: Time.zone.now,
        submitted_at: Time.zone.now,
        processed_at: nil
      )

      visit "higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit/select_issues"
      find("label", text: "PTSD denied").click
      safe_click("#button-submit-update")

      expect(page).to have_content("Previous update not yet done processing")
    end

    it "updates selected issues", skip: "save button in future PR" do
      allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
      allow(Fakes::VBMSService).to receive(:associate_rated_issues!).and_call_original
      allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original

      visit "higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit/select_issues"

      find("label", text: "Left knee granted").click
      find("label", text: "PTSD denied").click
      expect(page).to have_button("Save", disabled: false)

      safe_click("#button-submit-update")
      # verify that we are redirected to index
      expect(page).to have_current_path("/higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit/")

      # reload to verify that the new issues populate the form
      visit "higher_level_reviews/#{higher_level_review.end_product_claim_id}/edit/select_issues"
      expect(find_field("PTSD denied", visible: false)).to be_checked
      expect(find_field("Left knee granted", visible: false)).to_not be_checked

      # assert server has updated data
      new_request_issue = higher_level_review.reload.request_issues.first
      expect(new_request_issue.description).to eq("PTSD denied")
      expect(request_issue.reload.review_request_id).to be_nil
      expect(request_issue.removed_at).to be_within(1.hour).of(Time.current)
      expect(new_request_issue.rating_issue_associated_at).to be_within(1.hour).of(Time.current)

      # expect contentions to reflect issue update
      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        veteran_file_number: veteran.file_number,
        claim_id: higher_level_review.end_product_claim_id,
        contention_descriptions: ["PTSD denied"],
        special_issues: []
      )
      expect(Fakes::VBMSService).to have_received(:associate_rated_issues!).with(
        claim_id: higher_level_review.end_product_claim_id,
        rated_issue_contention_map: {
          new_request_issue.rating_issue_reference_id => new_request_issue.contention_reference_id
        }
      )
      expect(Fakes::VBMSService).to have_received(:remove_contention!).once
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
    end
  end

  context "Supplemental claims" do
    let!(:supplemental_claim) do
      SupplementalClaim.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        benefit_type: "compensation"
      )
    end

    let!(:request_issue) do
      RequestIssue.create!(
        rating_issue_reference_id: "def456",
        rating_issue_profile_date: rating.profile_date,
        review_request: supplemental_claim,
        description: "PTSD denied"
      )
    end

    before do
      supplemental_claim.create_issues!([request_issue])
      supplemental_claim.process_end_product_establishments!
      supplemental_claim.create_claimants!(participant_id: "5382910292", payee_code: "10")

      allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
        first_name: "BOB",
        last_name: "VANCE",
        ptcpnt_id: "5382910292",
        relationship_type: "Spouse"
      )
    end

    it "shows request issues and allows adding/removing issues" do
      visit "supplemental_claims/#{supplemental_claim.end_product_claim_id}/edit"

      # Check that request issues appear correctly as added issues
      expect(page).to_not have_content("Left knee granted")
      expect(page).to have_content("PTSD denied")

      expect(page).to have_content("Add Issues")
      check_row("Form", Constants.INTAKE_FORM_NAMES.supplemental_claim)
      check_row("Benefit type", "Compensation")
      check_row("Claimant", "Bob Vance, Spouse (payee code 10)")

      safe_click "#button-add-issue"

      expect(page).to have_content("Add issue 2")
      expect(page).to have_content("Does issue 2 match any of these issues")
      expect(page).to have_content("Left knee granted")
      expect(page).to have_content("PTSD denied")

      # test canceling adding an issue by closing the modal
      safe_click ".close-modal"
      expect(page).to_not have_content("2. Left knee granted")

      # adding an issue should show the issue
      safe_click "#button-add-issue"
      find("label", text: "Left knee granted").click
      safe_click ".add-issue"

      expect(page).to have_content("2. Left knee granted")
      expect(page).to_not have_content("Notes:")
      safe_click ".remove-issue"

      expect(page).not_to have_content("PTSD denied")

      # re-add to proceed
      safe_click "#button-add-issue"
      find("label", text: "PTSD denied").click
      fill_in "Notes", with: "I am an issue note"
      safe_click ".add-issue"
      expect(page).to have_content("2. PTSD denied")
      expect(page).to have_content("I am an issue note")

      # clicking add issue again should show a disabled radio button for that same rating
      safe_click "#button-add-issue"
      expect(page).to have_content("Add issue 3")
      expect(page).to have_content("Does issue 3 match any of these issues")
      expect(page).to have_content("Left knee granted (already selected for issue 1)")
      expect(page).to have_css("input[disabled][id='rating-radio_abc123']", visible: false)

      # Add non-rated issue
      safe_click ".no-matching-issues"
      expect(page).to have_content("Does issue 3 match any of these issue categories?")
      expect(page).to have_button("Add this issue", disabled: true)
      fill_in "Issue category", with: "Active Duty Adjustments"
      find("#issue-category").send_keys :enter
      fill_in "Issue description", with: "Description for Active Duty Adjustments"
      fill_in "Decision date", with: "04/25/2018"
      expect(page).to have_button("Add this issue", disabled: false)
      safe_click ".add-issue"
      expect(page).to have_content("3 issues")

      # add unidentified issue
      safe_click "#button-add-issue"
      safe_click ".no-matching-issues"
      safe_click ".no-matching-issues"
      expect(page).to have_content("Describe the issue to mark it as needing further review.")
      fill_in "Transcribe the issue as it's written on the form", with: "This is an unidentified issue"
      safe_click ".add-issue"
      expect(page).to have_content("4 issues")
      expect(page).to have_content("This is an unidentified issue")
    end

    it "enables save button only when dirty", skip: "save button in future PR" do
      visit "supplemental_claims/#{supplemental_claim.end_product_claim_id}/edit/select_issues"
      expect(page).to have_button("Save", disabled: true)

      find("label", text: "PTSD denied").click
      expect(find_field("PTSD denied", visible: false)).to be_checked
      expect(page).to have_button("Save", disabled: false)

      find("label", text: "PTSD denied").click
      expect(find_field("PTSD denied", visible: false)).to_not be_checked
      expect(page).to have_button("Save", disabled: true)
    end

    it "shows an error message if no issues are selected", skip: "save button in future PR" do
      visit "supplemental_claims/#{supplemental_claim.end_product_claim_id}/edit/select_issues"
      find("label", text: "Left knee granted").click
      expect(find_field("Left knee granted", visible: false)).to_not be_checked

      safe_click("#button-submit-update")

      expect(page).to have_content("No issues were selected")
    end

    it "updates selected issues", skip: "save button in future PR" do
      allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
      allow(Fakes::VBMSService).to receive(:associate_rated_issues!).and_call_original
      allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original

      visit "supplemental_claims/#{supplemental_claim.end_product_claim_id}/edit/select_issues"

      find("label", text: "Left knee granted").click
      find("label", text: "PTSD denied").click
      expect(page).to have_button("Save", disabled: false)

      safe_click("#button-submit-update")
      # verify that we are redirected to index
      expect(page).to have_current_path("/supplemental_claims/#{supplemental_claim.end_product_claim_id}/edit/")

      # revisit to verify that the new issues populate the form
      visit "supplemental_claims/#{supplemental_claim.end_product_claim_id}/edit/select_issues"
      expect(find_field("PTSD denied", visible: false)).to be_checked
      expect(find_field("Left knee granted", visible: false)).to_not be_checked

      # assert server has updated data
      new_request_issue = supplemental_claim.reload.request_issues.first
      expect(new_request_issue.description).to eq("PTSD denied")
      expect(request_issue.reload.review_request_id).to be_nil
      expect(request_issue.removed_at).to be_within(1.hour).of(Time.current)
      expect(new_request_issue.rating_issue_associated_at).to be_within(1.hour).of(Time.current)

      # expect contentions to reflect issue update
      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        veteran_file_number: veteran.file_number,
        claim_id: supplemental_claim.end_product_claim_id,
        contention_descriptions: ["PTSD denied"],
        special_issues: []
      )
      expect(Fakes::VBMSService).to have_received(:associate_rated_issues!).with(
        claim_id: supplemental_claim.end_product_claim_id,
        rated_issue_contention_map: {
          new_request_issue.rating_issue_reference_id => new_request_issue.contention_reference_id
        }
      )
      expect(Fakes::VBMSService).to have_received(:remove_contention!).once
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
    end
  end
end
