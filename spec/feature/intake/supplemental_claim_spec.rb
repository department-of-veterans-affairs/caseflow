require "rails_helper"

RSpec.feature "Supplemental Claim Intake" do
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

  it "Creates an end product" do
    Fakes::VBMSService.end_product_claim_id = "IAMANEPID"

    visit "/intake"
    safe_click ".Select"
    expect(page).to have_css(".cf-form-dropdown")
    expect(page).to have_content("RAMP Selection (VA Form 21-4138)")
    expect(page).to have_content("Request for Higher-Level Review (VA Form 20-0988)")
    expect(page).to have_content("Supplemental Claim (VA Form 21-526b)")
    expect(page).to have_content("Notice of Disagreement (VA Form 10182)")

    safe_click ".Select"
    fill_in "Which form are you processing?", with: "Supplemental Claim (VA Form 21-526b)"
    find("#form-select").send_keys :enter

    safe_click ".cf-submit.usa-button"

    expect(page).to have_content("process this Supplemental Claim (VA Form 21-526b).")

    fill_in "Search small", with: "12341234"

    click_on "Search"

    expect(page).to have_current_path("/intake/review-request")

    fill_in "What is the Receipt Date of this form?", with: "05/28/2018"
    safe_click "#button-submit-review"
    expect(page).to have_content(
      "Receipt date cannot be in the future."
    )

    fill_in "What is the Receipt Date of this form?", with: "04/20/2018"
    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")
    expect(page).to have_content("Finish processing")
    expect(page).to have_content("Decision date: 04/25/2018")
    expect(page).to have_content("Left knee granted")
    expect(page).to have_button("Establish EP", disabled: true)
    expect(page).to have_content("0 rated issues")

    supplemental_claim = SupplementalClaim.find_by(veteran_file_number: "12341234")

    expect(supplemental_claim).to_not be_nil
    expect(supplemental_claim.receipt_date).to eq(Date.new(2018, 4, 20))
    intake = Intake.find_by(veteran_file_number: "12341234")

    find("label", text: "PTSD denied").click
    expect(page).to have_content("1 rated issue")
    find("label", text: "Left knee granted").click
    expect(page).to have_content("2 rated issues")
    find("label", text: "Left knee granted").click
    expect(page).to have_content("1 rated issue")

    safe_click "#button-finish-intake"

    expect(page).to have_content("Request for Supplemental Claim (VA Form 21-526b) has been processed.")
    expect(page).to have_content(
      "Established EP: 040SCRAMA - Supplemental Claim Review Rating for Station 397 - ARC"
    )

    expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
      claim_hash: {
        benefit_type_code: "1",
        payee_code: "00",
        predischarge: false,
        claim_type: "Claim",
        station_of_jurisdiction: "397",
        date: supplemental_claim.receipt_date.to_date,
        end_product_modifier: "040",
        end_product_label: "Supplemental Claim Review Rating",
        end_product_code: "040SCRAMA",
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

    supplemental_claim.reload
    expect(supplemental_claim.end_product_reference_id).to eq("IAMANEPID")
    expect(supplemental_claim.request_issues.count).to eq 1
    expect(supplemental_claim.request_issues.first).to have_attributes(
      rating_issue_reference_id: "def456",
      rating_issue_profile_date: Date.new(2018, 4, 28),
      description: "PTSD denied"
    )
  end
end
