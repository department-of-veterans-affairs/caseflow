require "rails_helper"

RSpec.feature "Supplemental Claim Intake" do
  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)
    FeatureToggle.enable!(:test_facols)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 26))

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
  end

  after do
    FeatureToggle.disable!(:intakeAma)
    FeatureToggle.disable!(:test_facols)
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

  let(:receipt_date) { Date.new(2018, 4, 20) }

  let(:untimely_days) { 372.days }

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

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

  it "Creates an end product" do
    # Testing two relationships, tests 1 relationship in HRL and nil in Appeal
    allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
      [
        {
          first_name: "FOO",
          last_name: "BAR",
          ptcpnt_id: "5382910292",
          relationship_type: "Spouse"
        },
        {
          first_name: "BAZ",
          last_name: "QUX",
          ptcpnt_id: "5382910293",
          relationship_type: "Child"
        }
      ]
    )

    Generators::EndProduct.build(
      veteran_file_number: "12341234",
      bgs_attrs: { end_product_type_code: "040" }
    )

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

    expect(page).to_not have_content("Please select the claimant listed on the form.")
    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    expect(page).to have_content("Please select the claimant listed on the form.")
    expect(page).to have_content("Foo Bar, Spouse")
    expect(page).to have_content("Baz Qux, Child")

    find("label", text: "Baz Qux, Child", match: :prefer_exact).click

    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")

    visit "/intake/review-request"

    expect(find("#different-claimant-option_true", visible: false)).to be_checked
    expect(find_field("Baz Qux, Child", visible: false)).to be_checked

    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")

    expect(page).to have_content("Identify issues on")
    expect(page).to have_content("Decision date: 04/14/2017")
    expect(page).to have_content("Left knee granted")
    expect(page).to_not have_content("Untimely rating issue 1")
    expect(page).to have_button("Establish EP", disabled: true)
    expect(page).to have_content("0 issues")

    supplemental_claim = SupplementalClaim.find_by(veteran_file_number: "12341234")

    expect(supplemental_claim).to_not be_nil
    expect(supplemental_claim.receipt_date).to eq(receipt_date)
    expect(supplemental_claim.claimants.first).to have_attributes(
      participant_id: "5382910293"
    )
    intake = Intake.find_by(veteran_file_number: "12341234")

    find("label", text: "PTSD denied").click
    expect(page).to have_content("1 issue")
    find("label", text: "Left knee granted").click
    expect(page).to have_content("2 issues")
    find("label", text: "Left knee granted").click
    expect(page).to have_content("1 issue")

    safe_click "#button-add-issue"

    safe_click ".Select"

    fill_in "Issue category", with: "Active Duty Adjustments"
    find("#issue-category").send_keys :enter

    expect(page).to have_content("1 issue")

    fill_in "Issue description", with: "Description for Active Duty Adjustments"

    # To do: Change this to one issue once we implement decision date into issue count
    expect(page).to have_content("2 issues")

    fill_in "Decision date", with: "04/25/2018"

    expect(page).to have_content("2 issues")

    safe_click "#button-finish-intake"

    expect(page).to have_content("Request for Supplemental Claim (VA Form 21-526b) has been processed.")
    expect(page).to have_content(
      "Established EP: 040SCR - Supplemental Claim Rating for Station 397 - ARC"
    )

    expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
      claim_hash: {
        benefit_type_code: "1",
        payee_code: "00",
        predischarge: false,
        claim_type: "Claim",
        station_of_jurisdiction: "397",
        date: supplemental_claim.receipt_date.to_date,
        end_product_modifier: "041",
        end_product_label: "Supplemental Claim Rating",
        end_product_code: "040SCR",
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false
      },
      veteran_hash: intake.veteran.to_vbms_hash
    )

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      veteran_file_number: "12341234",
      claim_id: "IAMANEPID",
      contention_descriptions: ["Description for Active Duty Adjustments", "PTSD denied"]
    )

    intake.reload
    expect(intake.completed_at).to eq(Time.zone.now)

    expect(intake).to be_success

    resultant_end_product_establishment = EndProductEstablishment.find_by(source: supplemental_claim.reload)
    expect(resultant_end_product_establishment.reference_id).to eq("IAMANEPID")
    expect(supplemental_claim.request_issues.count).to eq 2
    expect(supplemental_claim.request_issues.first).to have_attributes(
      rating_issue_reference_id: "def456",
      rating_issue_profile_date: receipt_date - untimely_days + 4.days,
      description: "PTSD denied",
      decision_date: nil
    )
    expect(supplemental_claim.request_issues.last).to have_attributes(
      rating_issue_reference_id: nil,
      rating_issue_profile_date: nil,
      issue_category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      decision_date: 1.month.ago.to_date
    )

    visit "/supplemental_claims/IAMANEPID/edit"
    expect(page).to have_content("Veteran Name: Ed Merica")

    visit "/supplemental_claims/4321/edit"
    expect(page).to have_content("Page not found")
  end

  it "Shows a review error when something goes wrong" do
    intake = SupplementalClaimIntake.new(veteran_file_number: "12341234", user: current_user)
    intake.start!

    visit "/intake"

    fill_in "What is the Receipt Date of this form?", with: "04/20/2018"

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    ## Validate error message when complete intake fails
    expect_any_instance_of(SupplementalClaimIntake).to receive(:review!).and_raise("A random error. Oh no!")

    safe_click "#button-submit-review"

    expect(page).to have_content("Something went wrong")
    expect(page).to have_current_path("/intake/review-request")
  end
end
