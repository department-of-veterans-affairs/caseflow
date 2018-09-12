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
    allow(Fakes::VBMSService).to receive(:associate_rated_issues!).and_call_original
  end

  after do
    FeatureToggle.disable!(:intakeAma)
    FeatureToggle.disable!(:test_facols)
  end

  let(:veteran) do
    Generators::Veteran.build(file_number: "12341234", first_name: "Ed", last_name: "Merica")
  end

  let(:veteran_no_ratings) do
    Generators::Veteran.build(file_number: "55555555",
                              first_name: "Nora",
                              last_name: "Attings",
                              participant_id: "44444444")
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

    expect(page).to have_current_path("/intake/review_request")

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

    fill_in "What is the payee code for this claimant?", with: "11 - C&P First Child"
    find("#cf-payee-code").send_keys :enter

    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")

    visit "/intake/review_request"

    expect(find("#different-claimant-option_true", visible: false)).to be_checked
    expect(find_field("Baz Qux, Child", visible: false)).to be_checked

    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")

    expect(page).to have_content("Identify issues on")
    expect(page).to have_content("Decision date: 04/17/2017")
    expect(page).to have_content("Left knee granted")
    expect(page).to_not have_content("Untimely rating issue 1")
    expect(page).to have_button("Establish EP", disabled: true)
    expect(page).to have_content("0 issues")

    supplemental_claim = SupplementalClaim.find_by(veteran_file_number: "12341234")

    expect(supplemental_claim).to_not be_nil
    expect(supplemental_claim.receipt_date).to eq(receipt_date)
    expect(supplemental_claim.claimants.first).to have_attributes(
      participant_id: "5382910293",
      payee_code: "11"
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

    expect(page).to have_content("1 issue")

    fill_in "Decision date", with: "04/25/2018"

    expect(page).to have_content("2 issues")

    safe_click "#button-finish-intake"

    expect(page).to have_content("Request for Supplemental Claim (VA Form 21-526b) has been processed.")
    expect(page).to have_content(
      "Established EP: 040SCR - Supplemental Claim Rating for Station 397 - ARC"
    )

    # ratings end product
    expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
      claim_hash: {
        benefit_type_code: "1",
        payee_code: "11",
        predischarge: false,
        claim_type: "Claim",
        station_of_jurisdiction: "397",
        date: supplemental_claim.receipt_date.to_date,
        end_product_modifier: "042",
        end_product_label: "Supplemental Claim Rating",
        end_product_code: SupplementalClaim::END_PRODUCT_RATING_CODE,
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false,
        claimant_participant_id: "5382910293"
      },
      veteran_hash: intake.veteran.to_vbms_hash
    )

    ratings_end_product_establishment = EndProductEstablishment.find_by(
      source: intake.detail,
      code: SupplementalClaim::END_PRODUCT_RATING_CODE
    )

    expect(ratings_end_product_establishment).to have_attributes(
      claimant_participant_id: "5382910293",
      payee_code: "11"
    )

    # nonratings end product
    expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
      claim_hash: {
        benefit_type_code: "1",
        payee_code: "11",
        predischarge: false,
        claim_type: "Claim",
        station_of_jurisdiction: "397",
        date: supplemental_claim.receipt_date.to_date,
        end_product_modifier: "041",
        end_product_label: "Supplemental Claim Nonrating",
        end_product_code: SupplementalClaim::END_PRODUCT_NONRATING_CODE,
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false,
        claimant_participant_id: "5382910293"
      },
      veteran_hash: intake.veteran.to_vbms_hash
    )
    nonratings_end_product_establishment = EndProductEstablishment.find_by(
      source: intake.detail,
      code: SupplementalClaim::END_PRODUCT_NONRATING_CODE
    )

    expect(nonratings_end_product_establishment).to have_attributes(
      claimant_participant_id: "5382910293",
      payee_code: "11"
    )

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      veteran_file_number: "12341234",
      claim_id: ratings_end_product_establishment.reference_id,
      contention_descriptions: ["PTSD denied"],
      special_issues: []
    )
    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      veteran_file_number: "12341234",
      claim_id: nonratings_end_product_establishment.reference_id,
      contention_descriptions: ["Description for Active Duty Adjustments"],
      special_issues: []
    )

    rated_issue = supplemental_claim.request_issues.find_by(description: "PTSD denied")

    expect(Fakes::VBMSService).to have_received(:associate_rated_issues!).with(
      claim_id: ratings_end_product_establishment.reference_id,
      rated_issue_contention_map: {
        rated_issue.rating_issue_reference_id => rated_issue.contention_reference_id
      }
    )

    intake.reload
    expect(intake.completed_at).to eq(Time.zone.now)

    expect(intake).to be_success

    expect(supplemental_claim.request_issues.count).to eq 2
    expect(supplemental_claim.request_issues.first).to have_attributes(
      rating_issue_reference_id: "def456",
      rating_issue_profile_date: receipt_date - untimely_days + 4.days,
      description: "PTSD denied",
      decision_date: nil,
      rating_issue_associated_at: Time.zone.now
    )
    expect(supplemental_claim.request_issues.last).to have_attributes(
      rating_issue_reference_id: nil,
      rating_issue_profile_date: nil,
      issue_category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      decision_date: 1.month.ago.to_date
    )

    visit "/supplemental_claims/#{ratings_end_product_establishment.reference_id}/edit"
    expect(page).to have_content("Supplemental Claim (VA Form 21-526b)")
    expect(page).to have_content("Ed Merica (12341234)")
    expect(page).to have_content("04/20/2018")
    expect(page).to_not have_content("Informal conference request")
    expect(page).to_not have_content("Same office request")
    expect(page).to have_content("PTSD denied")

    safe_click ".cf-edit-issues-link"

    expect(page).to have_current_path(
      "/supplemental_claims/#{ratings_end_product_establishment.reference_id}/edit/select_issues"
    )

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
    expect(page).to have_current_path("/intake/review_request")
  end

  it "Allows a Veteran without ratings to create an intake" do
    supplemental_claim = SupplementalClaim.create!(
      veteran_file_number: veteran_no_ratings.file_number,
      receipt_date: 2.days.ago
    )

    SupplementalClaimIntake.create!(
      veteran_file_number: veteran_no_ratings.file_number,
      user: current_user,
      started_at: 5.minutes.ago,
      detail: supplemental_claim
    )

    Claimant.create!(
      review_request: supplemental_claim,
      participant_id: veteran_no_ratings.participant_id
    )

    supplemental_claim.start_review!

    visit "/intake"

    safe_click "#button-submit-review"

    expect(page).to have_content("This Veteran has no rated, disability issues")

    safe_click "#button-add-issue"

    safe_click ".Select"

    fill_in "Issue category", with: "Active Duty Adjustments"
    find("#issue-category").send_keys :enter
    fill_in "Issue description", with: "Description for Active Duty Adjustments"
    fill_in "Decision date", with: "04/19/2018"

    expect(page).to have_content("1 issue")

    safe_click "#button-finish-intake"

    expect(page).to have_content("Request for Supplemental Claim (VA Form 21-526b) has been processed.")
  end
end
