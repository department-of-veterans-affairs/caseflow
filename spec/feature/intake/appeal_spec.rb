require "rails_helper"

RSpec.feature "Appeal Intake" do
  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 20))
  end

  after do
    FeatureToggle.disable!(:intakeAma)
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:veteran) do
    Generators::Veteran.build(file_number: "22334455", first_name: "Ed", last_name: "Merica")
  end

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: Date.new(2018, 4, 25),
      profile_date: Date.new(2018, 4, 28),
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" }
      ]
    )
  end

  it "Creates an appeal" do
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

    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")

    appeal = TemporaryAppeal.find_by(veteran_file_number: "22334455")
    expect(appeal).to_not be_nil
    expect(appeal.receipt_date).to eq(Date.new(2018, 4, 20))
    expect(appeal.docket_type).to eq("evidence_submission")

    expect(page).to have_content("Finish processing")
    expect(page).to have_content("Decision date: 04/25/2018")
    expect(page).to have_content("Left knee granted")
  end
end
