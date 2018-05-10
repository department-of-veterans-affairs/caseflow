require "rails_helper"

RSpec.feature "Higher Level Review Intake" do
  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 26))

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
  end

  after do
    FeatureToggle.disable!(:intakeAma)
  end

  let(:veteran) do
    Generators::Veteran.build(file_number: "12341234", first_name: "Ed", last_name: "Merica")
  end

  let(:issues) do
    [
      Generators::Issue.build
    ]
  end

  let(:inaccessible) { false }

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
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

  it "Creates an end product and contentions for it" do
    Fakes::VBMSService.end_product_claim_id = "IAMANEPID"

    visit "/intake"
    safe_click ".Select"

    fill_in "Which form are you processing?", with: "Request for Higher-Level Review (VA Form 20-0988)"
    find("#form-select").send_keys :enter

    safe_click ".cf-submit.usa-button"

    expect(page).to have_content("Higher-Level Review (VA Form 20-0988)")

    fill_in "Search small", with: "12341234"

    click_on "Search"

    expect(page).to have_current_path("/intake/review-request")

    fill_in "What is the Receipt Date of this form?", with: "05/28/2018"
    safe_click "#button-submit-review"
    expect(page).to have_content(
      "Receipt date cannot be in the future."
    )
    expect(page).to have_content(
      "Please select an option."
    )

    fill_in "What is the Receipt Date of this form?", with: "04/20/2018"

    within_fieldset("Did the Veteran request an informal conference?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    within_fieldset("Did the Veteran request review by the same office?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")
    expect(page).to have_content("Finish processing")
    expect(page).to have_content("Decision date: 04/25/2018")
    expect(page).to have_content("Left knee granted")
    expect(page).to have_content("0 rated issues")

    higher_level_review = HigherLevelReview.find_by(veteran_file_number: "12341234")
    expect(higher_level_review).to_not be_nil
    expect(higher_level_review.receipt_date).to eq(Date.new(2018, 4, 20))
    expect(higher_level_review.informal_conference).to eq(true)
    expect(higher_level_review.same_office).to eq(false)

    intake = Intake.find_by(veteran_file_number: "12341234")

    find("label", text: "PTSD denied").click
    expect(page).to have_content("1 rated issue")
    find("label", text: "Left knee granted").click
    expect(page).to have_content("2 rated issues")
    find("label", text: "Left knee granted").click
    expect(page).to have_content("1 rated issue")

    safe_click "#button-finish-intake"

    expect(page).to have_content("Request for Higher Level Review (VA Form 20-0988) has been processed.")
    expect(page).to have_content(
      "Established EP: 030HLRAMA - Higher Level Review Rating for Station 397 - ARC"
    )

    expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
      claim_hash: {
        benefit_type_code: "1",
        payee_code: "00",
        predischarge: false,
        claim_type: "Claim",
        station_of_jurisdiction: "397",
        date: higher_level_review.receipt_date.to_date,
        end_product_modifier: "030",
        end_product_label: "Higher Level Review Rating",
        end_product_code: "030HLRAMA",
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false
      },
      veteran_hash: intake.veteran.to_vbms_hash
    )

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      veteran_file_number: "12341234",
      claim_id: "IAMANEPID",
      contention_descriptions: ["PTSD denied"]
    )

    intake.reload
    expect(intake.completed_at).to eq(Time.zone.now)

    expect(intake).to be_success

    higher_level_review.reload
    expect(higher_level_review.end_product_reference_id).to eq("IAMANEPID")
    expect(higher_level_review.request_issues.count).to eq 1
    expect(higher_level_review.request_issues.first).to have_attributes(
      rating_issue_reference_id: "def456",
      rating_issue_profile_date: Date.new(2018, 4, 28),
      description: "PTSD denied"
    )
  end
end
