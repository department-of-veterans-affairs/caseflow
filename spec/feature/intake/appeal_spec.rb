require "rails_helper"
require "support/intake_helpers"

RSpec.feature "Appeal Intake" do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:intake)
    # Test that this works when only enabled on the current user
    FeatureToggle.enable!(:intakeAma, users: [current_user.css_id])
    FeatureToggle.enable!(:intake_legacy_opt_in, users: [current_user.css_id])

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 11, 28))
  end

  after do
    FeatureToggle.disable!(:intakeAma, users: [current_user.css_id])
    FeatureToggle.disable!(:intake_legacy_opt_in, users: [current_user.css_id])
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:veteran_file_number) { "223344555" }

  let!(:veteran) do
    Generators::Veteran.build(
      file_number: veteran_file_number,
      first_name: "Ed",
      last_name: "Merica",
      participant_id: "55443322"
    )
  end

  let(:veteran_no_ratings) do
    Generators::Veteran.build(file_number: "555555555",
                              first_name: "Nora",
                              last_name: "Attings",
                              participant_id: "44444444")
  end

  let(:receipt_date) { Date.new(2018, 9, 20) }

  let(:untimely_days) { 372.days }

  let(:profile_date) { Date.new(2018, 9, 15).to_time(:local) }

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - 5.days,
      profile_date: profile_date,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" }
      ]
    )
  end

  let!(:untimely_rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - untimely_days - 1.day,
      profile_date: receipt_date - untimely_days - 3.days,
      issues: [
        { reference_id: "old123", decision_text: "Untimely rating issue 1" },
        { reference_id: "old456", decision_text: "Untimely rating issue 2" }
      ]
    )
  end

  let(:no_ratings_err) { Rating::NilRatingProfileListError.new("none!") }

  it "cancels an intake in progress when there is a NilRatingProfileListError" do
    allow_any_instance_of(Fakes::BGSService).to receive(:fetch_ratings_in_range).and_raise(no_ratings_err)
    start_appeal(veteran)
    intake = Intake.find_by(veteran_file_number: veteran_file_number)

    visit "/intake"
    expect(page).to have_content("Something went wrong")
    intake.reload
    expect(intake.completion_status).to eq("canceled")
    visit "/intake"
    expect(page).to_not have_content("Something went wrong")
    expect(page).to have_content("Which form are you processing?")
  end

  it "Creates an appeal" do
    # Testing no relationships in Appeal and Veteran is claimant, tests two relationships in HLR and one in SC
    allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(nil)

    visit "/intake"
    safe_click ".Select"

    fill_in "Which form are you processing?", with: Constants.INTAKE_FORM_NAMES.appeal
    find("#form-select").send_keys :enter

    safe_click ".cf-submit.usa-button"

    expect(page).to have_content(search_page_title)

    fill_in search_bar_title, with: veteran_file_number

    click_on "Search"
    expect(page).to have_current_path("/intake/review_request")

    fill_in "What is the Receipt Date of this form?", with: "12/15/2018"
    safe_click "#button-submit-review"

    expect(page).to have_content("Receipt date cannot be in the future.")
    expect(page).to have_content("Please select an option.")

    fill_in "What is the Receipt Date of this form?", with: "09/20/2018"

    within_fieldset("Which review option did the Veteran request?") do
      find("label", text: "Evidence Submission", match: :prefer_exact).click
    end

    expect(page).to_not have_content("Please select the claimant listed on the form.")
    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    expect(page).to have_content("Please select the claimant listed on the form.")
    expect(page).to_not have_content("Bob Vance, Spouse")
    expect(page).to_not have_content("Cathy Smith, Child")

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    within_fieldset("Did they agree to withdraw their issues from the legacy system?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")

    visit "/intake/review_request"

    expect(find_field("Evidence Submission", visible: false)).to be_checked
    expect(find("#different-claimant-option_false", visible: false)).to be_checked
    expect(find("#legacy-opt-in_false", visible: false)).to be_checked

    safe_click "#button-submit-review"

    appeal = Appeal.find_by(veteran_file_number: veteran_file_number)
    intake = Intake.find_by(veteran_file_number: veteran_file_number)

    expect(appeal).to_not be_nil
    expect(appeal.receipt_date).to eq(receipt_date)
    expect(appeal.docket_type).to eq("evidence_submission")
    expect(appeal.legacy_opt_in_approved).to eq(false)

    expect(page).to have_content("Identify issues on")

    expect(appeal.claimant_participant_id).to eq(
      intake.veteran.participant_id
    )

    expect(appeal.payee_code).to eq(nil)
    expect(page).to have_content("Decision date: 09/15/2018")
    expect(page).to have_content("Left knee granted")
    expect(page).to have_content("Untimely rating issue 1")

    find("label", text: "PTSD denied").click

    click_intake_add_issue

    safe_click ".Select"
    expect(page).to have_content("1 issue")

    fill_in "Issue category", with: "Active Duty Adjustments"
    find("#issue-category").send_keys :enter

    expect(page).to have_content("1 issue")

    fill_in "Issue description", with: "Description for Active Duty Adjustments"

    expect(page).to have_content("1 issue")

    fill_in "Decision date", with: "10/27/2018"

    expect(page).to have_content("2 issues")

    click_intake_finish

    expect(page).to have_content("Request for #{Constants.INTAKE_FORM_NAMES.appeal} has been processed.")
    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES_SHORT.appeal} created:")
    expect(page).to have_content("Issue: Active Duty Adjustments - Description for Active Duty Adjustments")

    intake.reload
    expect(intake.completed_at).to eq(Time.zone.now)

    expect(intake).to be_success

    appeal.reload
    expect(appeal.request_issues.count).to eq 2
    expect(appeal.request_issues.first).to have_attributes(
      rating_issue_reference_id: "def456",
      rating_issue_profile_date: profile_date,
      description: "PTSD denied",
      decision_date: nil
    )

    expect(appeal.request_issues.last).to have_attributes(
      rating_issue_reference_id: nil,
      rating_issue_profile_date: nil,
      issue_category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      decision_date: 1.month.ago.to_date
    )
  end

  it "Shows a review error when something goes wrong" do
    intake = AppealIntake.new(veteran_file_number: veteran_file_number, user: current_user)
    intake.start!

    visit "/intake"

    fill_in "What is the Receipt Date of this form?", with: "04/20/2018"

    within_fieldset("Which review option did the Veteran request?") do
      find("label", text: "Evidence Submission", match: :prefer_exact).click
    end

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    within_fieldset("Did they agree to withdraw their issues from the legacy system?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    ## Validate error message when complete intake fails
    expect_any_instance_of(AppealIntake).to receive(:review!).and_raise("A random error. Oh no!")

    safe_click "#button-submit-review"

    expect(page).to have_content("Something went wrong")
    expect(page).to have_current_path("/intake/review_request")
  end

  def start_appeal(test_veteran, veteran_is_not_claimant: false, legacy_opt_in_approved: false)
    appeal = Appeal.create!(
      veteran_file_number: test_veteran.file_number,
      receipt_date: receipt_date,
      docket_type: "evidence_submission",
      legacy_opt_in_approved: legacy_opt_in_approved,
      veteran_is_not_claimant: veteran_is_not_claimant
    )

    intake = AppealIntake.create!(
      veteran_file_number: test_veteran.file_number,
      user: current_user,
      started_at: 5.minutes.ago,
      detail: appeal
    )

    Claimant.create!(
      review_request: appeal,
      participant_id: test_veteran.participant_id
    )

    appeal.start_review!

    [appeal, intake]
  end

  it "Allows a Veteran without ratings to create an intake" do
    start_appeal(veteran_no_ratings)

    visit "/intake"

    safe_click "#button-submit-review"

    expect(page).to have_content("This Veteran has no rated, disability issues")

    click_intake_add_issue

    safe_click ".Select"

    fill_in "Issue category", with: "Active Duty Adjustments"
    find("#issue-category").send_keys :enter
    fill_in "Issue description", with: "Description for Active Duty Adjustments"
    fill_in "Decision date", with: "04/19/2018"

    expect(page).to have_content("1 issue")

    click_intake_finish

    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been processed.")
  end

  context "Veteran has no ratings" do
    scenario "the Add Issue modal skips directly to Nonrating Issue modal" do
      start_appeal(veteran_no_ratings)

      visit "/intake/add_issues"

      click_intake_add_issue

      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "Description for Active Duty Adjustments",
        date: "04/19/2018"
      )

      expect(page).to have_content("1 issue")

      click_intake_finish
    end
  end

  def check_row(label, text)
    row = find("tr", text: label)
    expect(row).to have_text(text)
  end

  scenario "For new Add / Remove Issues page" do
    duplicate_reference_id = "xyz789"
    old_reference_id = "old1234"
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - 40.days,
      profile_date: receipt_date - 50.days,
      issues: [
        { reference_id: "xyz123", decision_text: "Left knee granted 2" },
        { reference_id: "xyz456", decision_text: "PTSD denied 2" },
        { reference_id: duplicate_reference_id, decision_text: "Old injury in review" }
      ]
    )
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - 400.days,
      profile_date: receipt_date - 450.days,
      issues: [
        { reference_id: old_reference_id, decision_text: "Really old injury" }
      ]
    )

    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: DecisionReview.ama_activation_date - 5.days,
      profile_date: DecisionReview.ama_activation_date - 10.days,
      issues: [
        { decision_text: "Issue before AMA Activation from RAMP",
          reference_id: "ramp_ref_id" }
      ],
      associated_claims: { bnft_clm_tc: "683SCRRRAMP", clm_id: "ramp_claim_id" }
    )

    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: DecisionReview.ama_activation_date - 5.days,
      profile_date: DecisionReview.ama_activation_date - 11.days,
      issues: [
        { reference_id: "before_ama_ref_id", decision_text: "Non-RAMP Issue before AMA Activation" }
      ]
    )

    epe = create(:end_product_establishment, :active)
    request_issue_in_progress = create(
      :request_issue,
      end_product_establishment: epe,
      rating_issue_reference_id: duplicate_reference_id,
      description: "Old injury"
    )

    appeal, = start_appeal(veteran)
    visit "/intake/add_issues"

    expect(page).to have_content("Add / Remove Issues")
    check_row("Form", Constants.INTAKE_FORM_NAMES.appeal)
    check_row("Review option", "Evidence Submission")
    check_row("Claimant", "Ed Merica")

    # clicking the add issues button should bring up the modal
    click_intake_add_issue
    expect(page).to have_content("Add issue 1")
    expect(page).to have_content("Does issue 1 match any of these issues")
    expect(page).to have_content("Left knee granted 2")
    expect(page).to have_content("PTSD denied 2")

    # test canceling adding an issue by closing the modal
    safe_click ".close-modal"
    expect(page).to_not have_content("Left knee granted 2")

    # adding an issue should show the issue
    click_intake_add_issue
    add_intake_rating_issue("Left knee granted 2")

    expect(page).to have_content("1. Left knee granted 2")
    expect(page).to_not have_content("Notes:")

    # removing the issue should hide the issue
    click_remove_intake_issue("1")

    expect(page).to_not have_content("Left knee granted 2")

    # re-add to proceed
    click_intake_add_issue
    add_intake_rating_issue("Left knee granted 2", "I am an issue note")

    expect(page).to have_content("1. Left knee granted 2")
    expect(page).to have_content("I am an issue note")

    # clicking add issue again should show a disabled radio button for that same rating
    click_intake_add_issue

    expect(page).to have_content("Add issue 2")
    expect(page).to have_content("Does issue 2 match any of these issues")
    expect(page).to have_content("Left knee granted 2 (already selected for issue 1)")
    expect(page).to have_css("input[disabled][id='rating-radio_xyz123']", visible: false)

    # Add nonrating issue
    click_intake_no_matching_issues
    add_intake_nonrating_issue(
      category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      date: "10/27/2018"
    )
    expect(page).to have_content("2 issues")

    # this nonrating request issue is timely
    expect(page).to_not have_content(
      "Description for Active Duty Adjustments #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}"
    )

    # add unidentified issue
    expect(page).to_not have_css(".issue-unidentified")
    click_intake_add_issue
    add_intake_unidentified_issue("This is an unidentified issue")
    expect(page).to have_content("3 issues")
    expect(page).to have_content("This is an unidentified issue")
    expect(find_intake_issue_by_number(3)).to have_css(".issue-unidentified")
    expect_ineligible_issue(3)

    # add ineligible issue
    click_intake_add_issue
    add_intake_rating_issue("Old injury in review")
    expect(page).to have_content("4 issues")
    expect(page).to have_content("4. Old injury in review is ineligible because it's already under review as a Appeal")
    expect_ineligible_issue(4)

    # add untimely rating request issue
    click_intake_add_issue
    add_intake_rating_issue("Really old injury")
    add_untimely_exemption_response("Yes")
    expect(page).to have_content("5 issues")
    expect(page).to have_content("I am an exemption note")
    expect(page).to_not have_content("5. Really old injury #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}")
    expect_ineligible_issue(5)

    # remove and re-add with different answer to exemption
    click_remove_intake_issue("5")
    click_intake_add_issue
    add_intake_rating_issue("Really old injury")
    add_untimely_exemption_response("No")
    expect(page).to have_content("5 issues")
    expect(page).to have_content("I am an exemption note")
    expect(page).to have_content("5. Really old injury #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}")
    expect_ineligible_issue(5)

    # add untimely nonrating request issue
    click_intake_add_issue
    click_intake_no_matching_issues
    add_intake_nonrating_issue(
      category: "Active Duty Adjustments",
      description: "Another Description for Active Duty Adjustments",
      date: "04/19/2016"
    )
    add_untimely_exemption_response("No", "I am an untimely exemption")
    expect(page).to have_content("6 issues")
    expect(page).to have_content("I am an untimely exemption")
    expect(page).to have_content(
      "Another Description for Active Duty Adjustments #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}"
    )
    expect_ineligible_issue(6)

    # add before_ama ratings
    click_intake_add_issue
    add_intake_rating_issue("Non-RAMP Issue before AMA Activation")
    expect(page).to have_content(
      "7. Non-RAMP Issue before AMA Activation #{Constants.INELIGIBLE_REQUEST_ISSUES.before_ama}"
    )
    expect_ineligible_issue(7)

    # Eligible because it comes from a RAMP decision
    click_intake_add_issue
    add_intake_rating_issue("Issue before AMA Activation from RAMP")
    expect(page).to have_content("8. Issue before AMA Activation from RAMP Decision date:")

    # nonrating before_ama
    click_intake_add_issue
    click_intake_no_matching_issues
    add_intake_nonrating_issue(
      category: "Drill Pay Adjustments",
      description: "A nonrating issue before AMA",
      date: "10/19/2017"
    )
    expect(page).to have_content(
      "A nonrating issue before AMA #{Constants.INELIGIBLE_REQUEST_ISSUES.before_ama}"
    )
    expect_ineligible_issue(9)

    click_intake_finish

    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been processed.")
    expect(page).to have_content(RequestIssue::UNIDENTIFIED_ISSUE_MSG)
    expect(page).to have_content('Unidentified issue: no issue matched for requested "This is an unidentified issue"')

    success_checklist = find("ul.cf-success-checklist")
    expect(success_checklist).to_not have_content("Non-RAMP issue before AMA Activation")
    expect(success_checklist).to_not have_content("A nonrating issue before AMA")

    ineligible_checklist = find("ul.cf-ineligible-checklist")
    expect(ineligible_checklist).to have_content("Non-RAMP Issue before AMA Activation is ineligible")
    expect(ineligible_checklist).to have_content("A nonrating issue before AMA is ineligible")

    expect(Appeal.find_by(
             id: appeal.id,
             veteran_file_number: veteran.file_number,
             established_at: Time.zone.now
    )).to_not be_nil

    expect(RequestIssue.find_by(
             review_request: appeal,
             rating_issue_reference_id: "xyz123",
             description: "Left knee granted 2",
             notes: "I am an issue note"
    )).to_not be_nil

    expect(RequestIssue.find_by(
             review_request: appeal,
             description: "Really old injury",
             untimely_exemption: false,
             untimely_exemption_notes: "I am an exemption note"
    )).to_not be_nil

    active_duty_adjustments_request_issue = RequestIssue.find_by!(
      review_request_type: "Appeal",
      review_request_id: appeal.id,
      issue_category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      decision_date: 1.month.ago
    )

    expect(active_duty_adjustments_request_issue.untimely?).to eq(false)

    another_active_duty_adjustments_request_issue = RequestIssue.find_by!(
      review_request_type: "Appeal",
      review_request_id: appeal.id,
      issue_category: "Active Duty Adjustments",
      description: "Another Description for Active Duty Adjustments"
    )

    expect(another_active_duty_adjustments_request_issue.untimely?).to eq(true)
    expect(another_active_duty_adjustments_request_issue.untimely_exemption?).to eq(false)
    expect(another_active_duty_adjustments_request_issue.untimely_exemption_notes).to_not be_nil

    expect(RequestIssue.find_by(
             review_request: appeal,
             description: "This is an unidentified issue",
             is_unidentified: true
    )).to_not be_nil

    # Issues before AMA
    expect(RequestIssue.find_by(
             review_request: appeal,
             description: "Non-RAMP Issue before AMA Activation",
             ineligible_reason: :before_ama
    )).to_not be_nil

    expect(RequestIssue.find_by(
             review_request: appeal,
             description: "Issue before AMA Activation from RAMP",
             ineligible_reason: nil,
             ramp_claim_id: "ramp_claim_id"
    )).to_not be_nil

    expect(RequestIssue.find_by(
             review_request: appeal,
             description: "A nonrating issue before AMA",
             ineligible_reason: :before_ama
    )).to_not be_nil

    duplicate_request_issues = RequestIssue.where(rating_issue_reference_id: duplicate_reference_id)
    ineligible_issue = duplicate_request_issues.select(&:duplicate_of_issue_in_active_review?).first

    expect(duplicate_request_issues.count).to eq(2)
    expect(duplicate_request_issues).to include(request_issue_in_progress)
    expect(ineligible_issue).to_not eq(request_issue_in_progress)

    expect(RequestIssue.find_by(rating_issue_reference_id: old_reference_id).eligible?).to eq(false)
  end

  it "Shows a review error when something goes wrong" do
    start_appeal(veteran)
    visit "/intake/add_issues"

    click_intake_add_issue
    add_intake_rating_issue("Left knee granted", "I am an issue note")

    ## Validate error message when complete intake fails
    expect_any_instance_of(AppealIntake).to receive(:complete!).and_raise("A random error. Oh no!")

    click_intake_finish

    expect(page).to have_content("Something went wrong")
    expect(page).to have_current_path("/intake/add_issues")
  end

  scenario "canceling an appeal intake" do
    _, intake = start_appeal(veteran)
    visit "/intake/add_issues"

    expect(page).to have_content("Add / Remove Issues")
    safe_click "#cancel-intake"
    expect(find("#modal_id-title")).to have_content("Cancel Intake?")
    safe_click ".close-modal"
    expect(page).to_not have_css("#modal_id-title")
    safe_click "#cancel-intake"

    safe_click ".confirm-cancel"
    expect(page).to have_content("Make sure you’ve selected an option below.")
    within_fieldset("Please select the reason you are canceling this intake.") do
      find("label", text: "Other").click
    end
    safe_click ".confirm-cancel"
    expect(page).to have_content("Make sure you’ve filled out the comment box below.")
    fill_in "Tell us more about your situation.", with: "blue!"
    safe_click ".confirm-cancel"

    expect(page).to have_content("Welcome to Caseflow Intake!")
    expect(page).to_not have_css(".cf-modal-title")

    intake.reload
    expect(intake.completed_at).to eq(Time.zone.now)
    expect(intake.cancel_reason).to eq("other")
    expect(intake).to be_canceled
  end

  context "with active legacy appeal" do
    before do
      setup_legacy_opt_in_appeals(veteran.file_number)
    end

    context "with legacy_opt_in_approved" do
      scenario "adding issues" do
        start_appeal(veteran, legacy_opt_in_approved: true)
        visit "/intake/add_issues"

        click_intake_add_issue
        expect(page).to have_content("Next")
        add_intake_rating_issue("Left knee granted")

        # expect legacy opt in modal
        expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
        # do not show "inactive and ineligible" issues when legacy opt in is true
        expect(page).to_not have_content("typhoid arthritis")

        add_intake_rating_issue("intervertebral disc syndrome") # ineligible issue

        expect(page).to have_content(
          "Left knee granted #{Constants.INELIGIBLE_REQUEST_ISSUES.legacy_appeal_not_eligible}"
        )

        # Expect untimely exemption modal for untimely issue
        click_intake_add_issue
        add_intake_rating_issue("Untimely rating issue 1")
        add_intake_rating_issue("None of these match")
        add_untimely_exemption_response("Yes")

        expect(page).to have_content("Untimely rating issue 1")

        click_intake_add_issue
        click_intake_no_matching_issues
        add_intake_nonrating_issue(
          category: "Active Duty Adjustments",
          description: "Description for Active Duty Adjustments",
          date: "10/25/2017",
          legacy_issues: true
        )

        expect(page).to have_content("Does issue 3 match any of these VACOLS issues?")

        add_intake_rating_issue("None of these match")
        add_untimely_exemption_response("Yes")

        expect(page).to have_content("Description for Active Duty Adjustments")

        click_intake_finish

        ineligible_checklist = find("ul.cf-ineligible-checklist")
        expect(ineligible_checklist).to have_content(
          "Left knee granted #{Constants.INELIGIBLE_REQUEST_ISSUES.legacy_appeal_not_eligible}"
        )

        expect(RequestIssue.find_by(
                 description: "Left knee granted",
                 ineligible_reason: :legacy_appeal_not_eligible,
                 vacols_id: "vacols2",
                 vacols_sequence_id: "1"
        )).to_not be_nil
      end
    end

    context "with legacy opt in not approved" do
      scenario "adding issues" do
        start_appeal(veteran, legacy_opt_in_approved: false)
        visit "/intake/add_issues"
        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")

        expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
        # do not show inactive appeals when legacy opt in is false
        expect(page).to_not have_content("impairment of hip")
        expect(page).to_not have_content("typhoid arthritis")

        add_intake_rating_issue("ankylosis of hip")

        expect(page).to have_content(
          "Left knee granted #{Constants.INELIGIBLE_REQUEST_ISSUES.legacy_issue_not_withdrawn}"
        )

        click_intake_finish

        ineligible_checklist = find("ul.cf-ineligible-checklist")
        expect(ineligible_checklist).to have_content(
          "Left knee granted #{Constants.INELIGIBLE_REQUEST_ISSUES.legacy_issue_not_withdrawn}"
        )

        expect(RequestIssue.find_by(
                 description: "Left knee granted",
                 ineligible_reason: :legacy_issue_not_withdrawn,
                 vacols_id: "vacols1",
                 vacols_sequence_id: "1"
        )).to_not be_nil
      end
    end

    scenario "adding issue with legacy opt in disabled" do
      allow(FeatureToggle).to receive(:enabled?).and_call_original
      allow(FeatureToggle).to receive(:enabled?).with(:intake_legacy_opt_in, user: current_user).and_return(false)

      start_appeal(veteran)
      visit "/intake/add_issues"

      click_intake_add_issue
      expect(page).to have_content("Add this issue")
      add_intake_rating_issue("Left knee granted")
      expect(page).to have_content("Left knee granted")
    end
  end
end
