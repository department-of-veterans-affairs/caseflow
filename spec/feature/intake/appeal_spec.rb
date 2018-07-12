require "rails_helper"

RSpec.feature "Appeal Intake" do
  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)
    FeatureToggle.enable!(:test_facols)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 20))
  end

  after do
    FeatureToggle.disable!(:intakeAma)
    FeatureToggle.disable!(:test_facols)
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:veteran) do
    Generators::Veteran.build(
      file_number: "22334455",
      first_name: "Ed",
      last_name: "Merica",
      participant_id: "55443322"
    )
  end

  let(:receipt_date) { Date.new(2018, 4, 20) }

  let(:untimely_days) { 372.days }

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - untimely_days + 1.day,
      profile_date: receipt_date - untimely_days + 4.days,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" }
      ]
    )
  end

  let!(:untimely_rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - untimely_days,
      profile_date: receipt_date - untimely_days + 3.days,
      issues: [
        { reference_id: "abc123", decision_text: "Untimely rating issue 1" },
        { reference_id: "def456", decision_text: "Untimely rating issue 2" }
      ]
    )
  end

  it "Creates an appeal" do
    # Testing no relationships in Appeal and Veteran is claimant, tests two relationships in HRL and one in SC
    allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(nil)

    visit "/intake"
    safe_click ".Select"

    fill_in "Which form are you processing?", with: "Notice of Disagreement (VA Form 10182)"
    find("#form-select").send_keys :enter

    safe_click ".cf-submit.usa-button"

    expect(page).to have_content("Notice of Disagreement (VA Form 10182)")

    fill_in "Search small", with: "22334455"

    click_on "Search"

    expect(page).to have_current_path("/intake/review-request")

    fill_in "What is the Receipt Date of this form?", with: "05/25/2018"
    safe_click "#button-submit-review"

    expect(page).to have_content("Receipt date cannot be in the future.")
    expect(page).to have_content("Please select an option.")

    fill_in "What is the Receipt Date of this form?", with: "04/20/2018"

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

    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")

    visit "/intake/review-request"

    expect(find_field("Evidence Submission", visible: false)).to be_checked

    expect(find("#different-claimant-option_false", visible: false)).to be_checked

    safe_click "#button-submit-review"

    appeal = Appeal.find_by(veteran_file_number: "22334455")
    intake = Intake.find_by(veteran_file_number: "22334455")

    expect(appeal).to_not be_nil
    expect(appeal.receipt_date).to eq(receipt_date)
    expect(appeal.docket_type).to eq("evidence_submission")
    expect(appeal.claimants.first).to have_attributes(
      participant_id: veteran.participant_id
    )

    expect(page).to have_content("Identify issues on")
    expect(page).to have_content("Decision date: 04/14/2017")
    expect(page).to have_content("Left knee granted")
    expect(page).to_not have_content("Untimely rating issue 1")

    find("label", text: "PTSD denied").click

    safe_click "#button-add-issue"

    safe_click ".Select"

    fill_in "Issue category", with: "Active Duty Adjustments"
    find("#issue-category").send_keys :enter

    expect(page).to have_content("1 issue")

    fill_in "Issue description", with: "Description for Active Duty Adjustments"

    expect(page).to have_content("2 issues")

    safe_click "#button-finish-intake"

    expect(page).to have_content("Notice of Disagreement (VA Form 10182) has been processed.")

    intake.reload
    expect(intake.completed_at).to eq(Time.zone.now)

    expect(intake).to be_success

    appeal.reload
    expect(appeal.request_issues.count).to eq 2
    expect(appeal.request_issues.first).to have_attributes(
      rating_issue_reference_id: "def456",
      rating_issue_profile_date: receipt_date - untimely_days + 4.days,
      description: "PTSD denied"
    )

    expect(appeal.request_issues.last).to have_attributes(
      rating_issue_reference_id: nil,
      rating_issue_profile_date: nil,
      issue_category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments"
    )
  end

  it "Shows a review error when something goes wrong" do
    intake = AppealIntake.new(veteran_file_number: "22334455", user: current_user)
    intake.start!

    visit "/intake"

    fill_in "What is the Receipt Date of this form?", with: "04/20/2018"

    within_fieldset("Which review option did the Veteran request?") do
      find("label", text: "Evidence Submission", match: :prefer_exact).click
    end

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    ## Validate error message when complete intake fails
    expect_any_instance_of(AppealIntake).to receive(:review!).and_raise("A random error. Oh no!")

    safe_click "#button-submit-review"

    expect(page).to have_content("Something went wrong")
    expect(page).to have_current_path("/intake/review-request")
  end
end
