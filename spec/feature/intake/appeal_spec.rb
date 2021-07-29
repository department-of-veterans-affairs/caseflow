# frozen_string_literal: true

feature "Appeal Intake", :all_dbs do
  include IntakeHelpers

  before do
    Timecop.freeze(post_ama_start_date)
    BvaIntake.singleton.add_user(current_user)
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

  let(:future_date) { (Time.zone.now + 30.days).to_date }
  let(:receipt_date) { (post_ama_start_date - 30.days).to_date }
  let(:untimely_days) { 372.days }
  let(:profile_date) { (post_ama_start_date - 35.days).utc.to_datetime }
  let(:nonrating_date) { Time.zone.yesterday }
  let(:untimely_date) { (receipt_date - untimely_days - 1.day).to_date }
  let(:promulgation_date) { receipt_date - 5.days }
  let(:untimely_promulgation_date) { receipt_date - untimely_days - 1.day }
  let(:untimely_profile_date) { receipt_date - untimely_days - 3.days }

  let!(:rating) { generate_rating(veteran, promulgation_date, profile_date) }
  let!(:untimely_rating) { generate_untimely_rating(veteran, untimely_promulgation_date, untimely_profile_date) }
  let!(:before_ama_rating) { generate_pre_ama_rating(veteran) }

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
    allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(nil)

    visit "/intake"
    select_form(Constants.INTAKE_FORM_NAMES.appeal)

    safe_click ".cf-submit.usa-button"

    expect(page).to have_content(search_page_title)

    fill_in search_bar_title, with: veteran_file_number

    click_on "Search"
    expect(page).to have_current_path("/intake/review_request")

    fill_in "What is the Receipt Date of this form?", with: future_date.mdY
    click_intake_continue

    expect(page).to have_content("Receipt date cannot be in the future.")
    expect(page).to have_content("Please select an option.")

    fill_in "What is the Receipt Date of this form?", with: receipt_date.mdY

    within_fieldset("Was this form submitted through VA.gov?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    within_fieldset("Which review option did the Veteran request?") do
      find("label", text: "Evidence Submission", match: :prefer_exact).click
    end

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    select_agree_to_withdraw_legacy_issues(false)

    click_intake_continue

    expect(page).to have_current_path("/intake/add_issues")

    visit "/intake/review_request"

    expect(find_field("Evidence Submission", visible: false)).to be_checked
    expect(find("#different-claimant-option_false", visible: false)).to be_checked
    expect(find("#legacy-opt-in_false", visible: false)).to be_checked

    click_intake_continue

    appeal = Appeal.find_by(veteran_file_number: veteran_file_number)
    intake = Intake.find_by(veteran_file_number: veteran_file_number)

    expect(appeal).to_not be_nil
    expect(appeal.receipt_date.to_date).to eq(receipt_date.to_date)
    expect(appeal.docket_type).to eq(Constants.AMA_DOCKETS.evidence_submission)
    expect(appeal.legacy_opt_in_approved).to eq(false)
    expect(appeal.filed_by_va_gov).to eq(true)
    expect(appeal.claimant_participant_id).to eq(
      intake.veteran.participant_id
    )
    expect(appeal.payee_code).to eq(nil)

    expect(page).to have_current_path("/intake/add_issues")

    click_intake_add_issue
    add_intake_rating_issue("PTSD denied")
    expect(page).to have_content("1 issue")

    click_intake_add_issue
    click_intake_no_matching_issues
    add_intake_nonrating_issue(
      category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      date: nonrating_date.mdY
    )

    expect(page).to have_content("2 issues")

    click_intake_finish

    expect(page).to have_content("Request for #{Constants.INTAKE_FORM_NAMES.appeal} has been submitted.")
    expect(page).not_to have_content("It may take up to 24 hours for the claim to establish")
    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES_SHORT.appeal} created:")
    expect(page).to have_content("Issue: Active Duty Adjustments - Description for Active Duty Adjustments")

    intake.reload
    expect(intake.completed_at).to eq(Time.zone.now)

    expect(intake).to be_success

    appeal.reload

    expect(appeal.request_issues.count).to eq 2

    rating_request_issue = appeal.request_issues.rating.first
    nonrating_request_issue = appeal.request_issues.nonrating.first

    expect(rating_request_issue).to have_attributes(
      contested_rating_issue_reference_id: "def456",
      contested_rating_issue_profile_date: profile_date.to_s,
      contested_issue_description: "PTSD denied",
      decision_date: promulgation_date,
      benefit_type: "compensation"
    )

    expect(nonrating_request_issue).to have_attributes(
      contested_rating_issue_reference_id: nil,
      contested_rating_issue_profile_date: nil,
      nonrating_issue_category: "Active Duty Adjustments",
      nonrating_issue_description: "Description for Active Duty Adjustments",
      benefit_type: "compensation"
    )
    expect(nonrating_request_issue.decision_date.to_date).to eq(nonrating_date)
  end

  it "Shows a review error when something goes wrong" do
    intake = AppealIntake.new(veteran_file_number: veteran_file_number, user: current_user)
    intake.start!

    visit "/intake"

    fill_in "What is the Receipt Date of this form?", with: receipt_date.mdY

    within_fieldset("Was this form submitted through VA.gov?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    within_fieldset("Which review option did the Veteran request?") do
      find("label", text: "Evidence Submission", match: :prefer_exact).click
    end

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    select_agree_to_withdraw_legacy_issues(false)

    ## Validate error message when complete intake fails
    expect_any_instance_of(AppealIntake).to receive(:review!).and_raise("A random error. Oh no!")

    click_intake_continue

    expect(page).to have_content("Something went wrong")
    expect(page).to have_current_path("/intake/review_request")
  end

  def start_appeal(test_veteran, veteran_is_not_claimant: false, legacy_opt_in_approved: false)
    appeal = Appeal.create!(
      veteran_file_number: test_veteran.file_number,
      receipt_date: receipt_date,
      docket_type: Constants.AMA_DOCKETS.evidence_submission,
      legacy_opt_in_approved: legacy_opt_in_approved,
      veteran_is_not_claimant: veteran_is_not_claimant,
      filed_by_va_gov: false
    )

    intake = AppealIntake.create!(
      veteran_file_number: test_veteran.file_number,
      user: current_user,
      started_at: 5.minutes.ago,
      detail: appeal
    )

    VeteranClaimant.create!(
      decision_review: appeal,
      participant_id: test_veteran.participant_id
    )

    appeal.start_review!

    [appeal, intake]
  end

  it "Allows a Veteran without ratings to create an intake" do
    start_appeal(veteran_no_ratings)

    visit "/intake"

    click_intake_continue
    click_intake_add_issue
    add_intake_nonrating_issue(
      category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      date: nonrating_date.mdY
    )

    expect(page).to have_content("1 issue")

    click_intake_finish

    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been submitted.")
  end

  def complete_appeal
    start_appeal(veteran_no_ratings)

    visit "/intake"
    click_intake_continue
    click_intake_add_issue

    # expect the rating modal to be skipped
    expect(page).to have_content("Does issue 1 match any of these non-rating issue categories?")
    add_intake_nonrating_issue(
      category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      date: nonrating_date.mdY
    )

    click_intake_finish
    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been submitted.")
  end

  scenario "intake can still be completed when ratings are backfilled" do
    mock_backfilled_rating_response
    complete_appeal
  end

  scenario "intake can still be completed when ratings are locked" do
    mock_locked_rating_response
    complete_appeal
  end

  context "ratings with diagnostic codes" do
    let(:disabiliity_receive_date) { receipt_date + 2.days }
    let(:disability_profile_date) { profile_date - 1.day }
    let!(:ratings_with_diagnostic_codes) do
      generate_ratings_with_disabilities(
        veteran,
        disabiliity_receive_date,
        disability_profile_date
      )
    end

    scenario "saves diagnostic codes" do
      appeal, = start_appeal(veteran)
      visit "/intake"
      click_intake_continue
      save_and_check_request_issues_with_diagnostic_codes(
        Constants.INTAKE_FORM_NAMES.appeal,
        appeal
      )
    end
  end

  context "Veteran has no ratings" do
    scenario "the Add Issue modal skips directly to Nonrating Issue modal" do
      start_appeal(veteran_no_ratings)

      visit "/intake/add_issues"

      click_intake_add_issue

      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "Description for Active Duty Adjustments",
        date: nonrating_date.mdY
      )

      expect(page).to have_content("1 issue")

      click_intake_finish
    end
  end

  scenario "Add / Remove Issues page" do
    duplicate_reference_id = "xyz789"
    old_reference_id = "old1234"
    promulgation_date = receipt_date - 40.days
    rating_date = promulgation_date.mdY

    generate_timely_rating(veteran, receipt_date, duplicate_reference_id)
    generate_untimely_rating_from_ramp(veteran, receipt_date, old_reference_id)
    generate_rating_before_ama_from_ramp(veteran)

    epe = create(:end_product_establishment, :active)
    request_issue_in_progress = create(
      :request_issue,
      end_product_establishment: epe,
      contested_rating_issue_reference_id: duplicate_reference_id,
      contested_issue_description: "Old injury"
    )

    appeal, = start_appeal(veteran)
    visit "/intake/add_issues"

    expect(page).to have_content("Add / Remove Issues")
    check_row("Review option", "Evidence Submission")
    check_row("Claimant", "Ed Merica, Veteran")
    check_row("SOC/SSOC Opt-in", "No")

    # clicking the add issues button should bring up the modal
    click_intake_add_issue
    expect(page).to have_content("Past decisions from #{rating_date}")
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
    expect(page).to have_css("input[disabled]", visible: false)

    # Add nonrating issue
    click_intake_no_matching_issues
    add_intake_nonrating_issue(
      category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      date: nonrating_date.mdY
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

    # add ineligible issue
    click_intake_add_issue
    add_intake_rating_issue("Old injury")
    expect(page).to have_content("4 issues")
    expect(page).to have_content("4. Old injury is ineligible because it's already under review as a Appeal")
    expect_ineligible_issue(4)

    # add untimely rating request issue
    click_intake_add_issue
    add_intake_rating_issue("Really old injury")
    add_untimely_exemption_response("Yes")
    expect(page).to have_content("5 issues")
    expect(page).to have_content("I am an exemption note")
    expect(page).to_not have_content("5. Really old injury #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}")

    # remove and re-add with different answer to exemption
    click_remove_intake_issue("5")
    click_intake_add_issue
    add_intake_rating_issue("Really old injury")
    add_untimely_exemption_response("No")
    expect(page).to have_content("5 issues")
    expect(page).to have_content("5. Really old injury #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}")
    expect_ineligible_issue(5)

    # add untimely nonrating request issue
    click_intake_add_issue
    click_intake_no_matching_issues
    add_intake_nonrating_issue(
      category: "Active Duty Adjustments",
      description: "Another Description for Active Duty Adjustments",
      date: untimely_date.mdY
    )
    add_untimely_exemption_response("No")
    expect(page).to have_content("6 issues")
    expect(page).to have_content(
      "Another Description for Active Duty Adjustments #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}"
    )
    expect_ineligible_issue(6)

    # add before_ama ratings
    click_intake_add_issue
    add_intake_rating_issue("Non-RAMP Issue before AMA Activation")
    add_untimely_exemption_response("Yes")
    expect(page).to have_content(
      "7. Non-RAMP Issue before AMA Activation #{Constants.INELIGIBLE_REQUEST_ISSUES.before_ama}"
    )
    expect_ineligible_issue(7)

    # Eligible because it comes from a RAMP decision
    click_intake_add_issue
    add_intake_rating_issue("Issue before AMA Activation from RAMP")
    add_untimely_exemption_response("Yes")
    expect(page).to have_content("8. Issue before AMA Activation from RAMP\nDecision date:")

    # nonrating before_ama
    click_intake_add_issue
    click_intake_no_matching_issues
    add_intake_nonrating_issue(
      category: "Drill Pay Adjustments",
      description: "A nonrating issue before AMA",
      date: pre_ramp_start_date.to_date.mdY
    )
    add_untimely_exemption_response("Yes")
    expect(page).to have_content(
      "A nonrating issue before AMA #{Constants.INELIGIBLE_REQUEST_ISSUES.before_ama}"
    )
    expect_ineligible_issue(9)

    click_intake_finish

    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been submitted.")
    expect(page).to have_content(RequestIssue::UNIDENTIFIED_ISSUE_MSG)
    expect(page).to have_content('Unidentified issue: no issue matched for requested "This is an unidentified issue"')

    success_checklist = find("ul.cf-success-checklist")
    expect(success_checklist).to_not have_content("Non-RAMP issue before AMA Activation")
    expect(success_checklist).to_not have_content("A nonrating issue before AMA")

    ineligible_checklist = find("ul.cf-issue-checklist")
    expect(ineligible_checklist).to have_content("Non-RAMP Issue before AMA Activation is ineligible")
    expect(ineligible_checklist).to have_content("A nonrating issue before AMA is ineligible")

    expect(Appeal.find_by(
             id: appeal.id,
             veteran_file_number: veteran.file_number,
             established_at: Time.zone.now
           )).to_not be_nil

    expect(RequestIssue.find_by(
             decision_review: appeal,
             contested_rating_issue_reference_id: "xyz123",
             contested_issue_description: "Left knee granted 2",
             notes: "I am an issue note"
           )).to_not be_nil

    expect(RequestIssue.find_by(
             decision_review: appeal,
             contested_issue_description: "Really old injury",
             untimely_exemption: false
           )).to_not be_nil

    active_duty_adjustments_request_issue = RequestIssue.find_by!(
      decision_review: appeal,
      nonrating_issue_category: "Active Duty Adjustments",
      nonrating_issue_description: "Description for Active Duty Adjustments",
      decision_date: nonrating_date
    )

    expect(active_duty_adjustments_request_issue.untimely?).to eq(false)

    another_active_duty_adjustments_request_issue = RequestIssue.find_by!(
      decision_review_type: "Appeal",
      decision_review_id: appeal.id,
      nonrating_issue_category: "Active Duty Adjustments",
      nonrating_issue_description: "Another Description for Active Duty Adjustments"
    )

    expect(another_active_duty_adjustments_request_issue.untimely?).to eq(true)
    expect(another_active_duty_adjustments_request_issue.untimely_exemption?).to eq(false)
    expect(another_active_duty_adjustments_request_issue.untimely_exemption_notes).to_not be_nil

    expect(RequestIssue.find_by(
             decision_review: appeal,
             unidentified_issue_text: "This is an unidentified issue",
             is_unidentified: true
           )).to_not be_nil

    # Issues before AMA
    expect(RequestIssue.find_by(
             decision_review: appeal,
             contested_issue_description: "Non-RAMP Issue before AMA Activation",
             ineligible_reason: :before_ama,
             closed_status: :ineligible
           )).to_not be_nil

    expect(RequestIssue.find_by(
             decision_review: appeal,
             contested_issue_description: "Issue before AMA Activation from RAMP",
             ineligible_reason: nil,
             ramp_claim_id: "ramp_claim_id"
           )).to_not be_nil

    expect(RequestIssue.find_by(
             decision_review: appeal,
             nonrating_issue_description: "A nonrating issue before AMA",
             ineligible_reason: :before_ama,
             closed_status: :ineligible
           )).to_not be_nil

    expect(RequestIssue.find_by(
             decision_review: appeal,
             nonrating_issue_description: "A nonrating issue before AMA",
             decision_date: pre_ramp_start_date
           )).to_not be_nil

    duplicate_request_issues = RequestIssue.where(contested_rating_issue_reference_id: duplicate_reference_id)
    ineligible_issue = duplicate_request_issues.detect(&:duplicate_of_rating_issue_in_active_review?)

    expect(duplicate_request_issues.count).to eq(2)
    expect(duplicate_request_issues).to include(request_issue_in_progress)
    expect(ineligible_issue).to_not eq(request_issue_in_progress)

    expect(RequestIssue.find_by(contested_rating_issue_reference_id: old_reference_id).eligible?).to eq(false)
  end

  context "when veteran chooses decision issue from a previous appeal" do
    let(:previous_appeal) { create(:appeal, :outcoded, veteran: veteran) }
    let(:appeal_reference_id) { "appeal123" }
    let!(:previous_appeal_request_issue) do
      create(
        :request_issue,
        decision_review: previous_appeal,
        contested_rating_issue_reference_id: appeal_reference_id,
        closed_at: 2.months.ago
      )
    end

    let!(:previous_appeal_decision_issue) do
      create(
        :decision_issue,
        decision_review: previous_appeal,
        request_issues: [previous_appeal_request_issue],
        rating_issue_reference_id: appeal_reference_id,
        participant_id: veteran.participant_id,
        description: "appeal decision issue",
        decision_text: "appeal decision issue",
        benefit_type: "compensation",
        caseflow_decision_date: profile_date
      )
    end

    scenario "the issue is ineligible" do
      start_appeal(
        veteran,
        veteran_is_not_claimant: false
      )
      visit "/intake/add_issues"

      expect(page).to have_content("Add / Remove Issues")

      click_intake_add_issue
      add_intake_rating_issue("appeal decision issue")
      expect(page).to have_content(
        "appeal decision issue #{Constants.INELIGIBLE_REQUEST_ISSUES.appeal_to_appeal}"
      )
      click_intake_finish

      expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been submitted.")
      expect(
        RequestIssue.find_by(contested_issue_description: "appeal decision issue").ineligible_reason
      ).to eq("appeal_to_appeal")
      ineligible_checklist = find("ul.cf-issue-checklist")
      expect(ineligible_checklist).to have_content(
        "appeal decision issue #{Constants.INELIGIBLE_REQUEST_ISSUES.appeal_to_appeal}"
      )
    end
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

  scenario "adding nonrating issue with non-comp benefit type" do
    _, intake = start_appeal(veteran)
    visit "/intake/add_issues"

    expect(page).to have_content("Add / Remove Issues")

    click_intake_add_issue
    click_intake_no_matching_issues
    add_intake_nonrating_issue(
      benefit_type: "Education",
      category: "Accrued",
      description: "Description for Accrued",
      date: nonrating_date.mdY
    )

    expect(page).to have_content("Description for Accrued")

    click_intake_add_issue
    click_intake_no_matching_issues
    add_intake_nonrating_issue(
      benefit_type: "Vocational Rehabilitation and Employment",
      category: "Basic Eligibility",
      description: "Description for basic eligibility",
      date: nonrating_date.mdY
    )

    expect(page).to have_content("Description for basic eligibility")

    click_intake_finish

    expect(page).to have_content("Intake completed")

    intake.reload

    education_request_issue = intake.detail.request_issues.find { |ri| ri.benefit_type == "education" }
    voc_rehab_request_issue = intake.detail.request_issues.find { |ri| ri.benefit_type == "voc_rehab" }

    expect(education_request_issue.description).to eq("Accrued - Description for Accrued")
    expect(voc_rehab_request_issue.description).to eq("Basic Eligibility - Description for basic eligibility")
  end

  context "with active legacy appeal" do
    before do
      setup_legacy_opt_in_appeals(veteran.file_number)
    end

    context "with legacy_opt_in_approved" do
      let(:receipt_date) { Time.zone.today }

      scenario "adding issues" do
        start_appeal(veteran, legacy_opt_in_approved: true)
        visit "/intake/add_issues"

        check_row("SOC/SSOC Opt-in", "Yes")

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
        select_intake_no_match
        add_untimely_exemption_response("Yes")

        expect(page).to have_content("Untimely rating issue 1")

        click_intake_add_issue
        click_intake_no_matching_issues
        add_intake_nonrating_issue(
          category: "Active Duty Adjustments",
          description: "Description for Active Duty Adjustments",
          date: nonrating_date.mdY,
          legacy_issues: true
        )

        expect(page).to have_content("Does issue 3 match any of these VACOLS issues?")

        select_intake_no_match

        expect(page).to have_content("Description for Active Duty Adjustments")

        # add before_ama ratings
        click_intake_add_issue
        add_intake_rating_issue("Non-RAMP Issue before AMA Activation")
        add_intake_rating_issue("limitation of thigh motion (extension)")

        expect(page).to have_content("Non-RAMP Issue before AMA Activation")
        expect(page).to_not have_content(
          "Non-RAMP Issue before AMA Activation #{Constants.INELIGIBLE_REQUEST_ISSUES.before_ama}"
        )

        # add eligible legacy issue
        click_intake_add_issue
        add_intake_rating_issue("PTSD denied")
        add_intake_rating_issue("ankylosis of hip")

        expect(page).to have_content(
          "#{COPY::VACOLS_OPTIN_ISSUE_NEW}:\nService connection, ankylosis of hip"
        )

        click_intake_finish

        ineligible_checklist = find("ul.cf-issue-checklist")
        expect(ineligible_checklist).to have_content(
          "Left knee granted #{Constants.INELIGIBLE_REQUEST_ISSUES.legacy_appeal_not_eligible}"
        )

        expect(RequestIssue.find_by(
                 contested_issue_description: "Left knee granted",
                 ineligible_reason: :legacy_appeal_not_eligible,
                 vacols_id: "vacols2",
                 vacols_sequence_id: "1"
               )).to_not be_nil

        expect(page).to have_content(COPY::VACOLS_OPTIN_ISSUE_CLOSED)
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

        ineligible_checklist = find("ul.cf-issue-checklist")
        expect(ineligible_checklist).to have_content(
          "Left knee granted #{Constants.INELIGIBLE_REQUEST_ISSUES.legacy_issue_not_withdrawn}"
        )

        expect(RequestIssue.find_by(
                 contested_issue_description: "Left knee granted",
                 ineligible_reason: :legacy_issue_not_withdrawn,
                 vacols_id: "vacols1",
                 vacols_sequence_id: "1"
               )).to_not be_nil

        expect(page).to_not have_content(COPY::VACOLS_OPTIN_ISSUE_CLOSED)
      end
    end
  end

  context "has prior non-comp claims with decision issues" do
    let(:prior_noncomp_decision_review) do
      create(:higher_level_review,
             benefit_type: "nca",
             veteran_file_number: veteran_no_ratings.file_number)
    end
    # decision_issue_date needs to be before receipt date to show up
    let(:decision_issue_date) { receipt_date - 2.days }
    let!(:decision_issues) do
      [
        # non comp decision issues do not have end_product_last_action date
        # but do have promulgation date
        create(:decision_issue,
               disposition: "Granted",
               description: "granted issue",
               participant_id: veteran_no_ratings.participant_id,
               decision_review: prior_noncomp_decision_review,
               caseflow_decision_date: decision_issue_date),
        create(:decision_issue,
               disposition: "Dismissed",
               description: "dismissed issue",
               participant_id: veteran_no_ratings.participant_id,
               decision_review: prior_noncomp_decision_review,
               caseflow_decision_date: decision_issue_date)
      ]
    end

    it "shows prior decision issues as contestable" do
      start_appeal(veteran_no_ratings)

      visit "/intake/add_issues"
      click_intake_add_issue
      expect(page).to have_content(decision_issue_date.mdY)
      expect(page).to have_content("granted issue")
      expect(page).to have_content("dismissed issue")
    end
  end

  context "has a chain of prior decision issues" do
    let(:start_date) { Time.zone.today - 300.days }
    before do
      prior_appeal = create(:appeal, :outcoded, veteran: veteran)
      request_issue = create(:request_issue,
                             contested_rating_issue_reference_id: "old123",
                             contested_rating_issue_profile_date: untimely_rating.profile_date,
                             decision_review: prior_appeal)
      setup_prior_decision_issue_chain(prior_appeal, request_issue, veteran, start_date)
    end

    it "disables prior contestable issues" do
      start_appeal(veteran)
      check_decision_issue_chain(start_date)
    end
  end
end
