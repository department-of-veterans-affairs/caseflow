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

  let(:benefit_type) { "compensation" }

  let(:untimely_days) { 372.days }

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:profile_date) { (receipt_date - untimely_days + 4.days).to_time(:local) }

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - untimely_days + 1.day,
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
      promulgation_date: receipt_date - untimely_days,
      profile_date: profile_date - 1.day,
      issues: [
        { reference_id: "old123", decision_text: "Untimely rating issue 1" },
        { reference_id: "old456", decision_text: "Untimely rating issue 2" }
      ]
    )
  end

  let(:search_bar_title) { "Enter the Veteran's ID" }
  let(:search_page_title) { "Search for Veteran ID" }

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
    expect(page).to have_content(Constants.INTAKE_FORM_NAMES.ramp_refiling)
    expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
    expect(page).to have_content(Constants.INTAKE_FORM_NAMES.supplemental_claim)
    expect(page).to have_content(Constants.INTAKE_FORM_NAMES.appeal)

    safe_click ".Select"
    fill_in "Which form are you processing?", with: Constants.INTAKE_FORM_NAMES.supplemental_claim
    find("#form-select").send_keys :enter

    safe_click ".cf-submit.usa-button"

    expect(page).to have_content(search_page_title)

    fill_in search_bar_title, with: "12341234"

    click_on "Search"

    expect(page).to have_current_path("/intake/review_request")

    within_fieldset("What is the Benefit Type?") do
      find("label", text: "Compensation", match: :prefer_exact).click
    end

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
    expect(page).to have_content("Untimely rating issue 1")
    expect(page).to have_button("Establish EP", disabled: true)
    expect(page).to have_content("0 issues")

    supplemental_claim = SupplementalClaim.find_by(veteran_file_number: "12341234")

    expect(supplemental_claim).to_not be_nil
    expect(supplemental_claim.receipt_date).to eq(receipt_date)
    expect(supplemental_claim.benefit_type).to eq(benefit_type)
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

    expect(page).to have_content("Request for #{Constants.INTAKE_FORM_NAMES.supplemental_claim} has been processed.")
    expect(page).to have_content(
      "Established EP: 040SCR - Supplemental Claim Rating for Station 499"
    )

    # ratings end product
    expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
      claim_hash: {
        benefit_type_code: "1",
        payee_code: "11",
        predischarge: false,
        claim_type: "Claim",
        station_of_jurisdiction: "499",
        date: supplemental_claim.receipt_date.to_date,
        end_product_modifier: "042",
        end_product_label: "Supplemental Claim Rating",
        end_product_code: SupplementalClaim::END_PRODUCT_CODES[:rating],
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false,
        claimant_participant_id: "5382910293"
      },
      veteran_hash: intake.veteran.to_vbms_hash
    )

    ratings_end_product_establishment = EndProductEstablishment.find_by(
      source: intake.detail,
      code: SupplementalClaim::END_PRODUCT_CODES[:rating]
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
        station_of_jurisdiction: "499",
        date: supplemental_claim.receipt_date.to_date,
        end_product_modifier: "041",
        end_product_label: "Supplemental Claim Nonrating",
        end_product_code: SupplementalClaim::END_PRODUCT_CODES[:nonrating],
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false,
        claimant_participant_id: "5382910293"
      },
      veteran_hash: intake.veteran.to_vbms_hash
    )
    nonratings_end_product_establishment = EndProductEstablishment.find_by(
      source: intake.detail,
      code: SupplementalClaim::END_PRODUCT_CODES[:nonrating]
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
      rating_issue_profile_date: profile_date,
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
    expect(page).to have_content(Constants.INTAKE_FORM_NAMES.supplemental_claim)
    expect(page).to have_content("Ed Merica (12341234)")
    expect(page).to have_content("04/20/2018")
    expect(page).to_not have_content("Informal conference request")
    expect(page).to_not have_content("Same office request")
    expect(page).to have_content("PTSD denied")

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

  def start_supplemental_claim(test_veteran, is_comp: true)
    supplemental_claim = SupplementalClaim.create!(
      veteran_file_number: test_veteran.file_number,
      receipt_date: 2.days.ago,
      benefit_type: is_comp ? "compensation" : "education"
    )

    intake = SupplementalClaimIntake.create!(
      veteran_file_number: test_veteran.file_number,
      user: current_user,
      started_at: 5.minutes.ago,
      detail: supplemental_claim
    )

    Claimant.create!(
      review_request: supplemental_claim,
      participant_id: test_veteran.participant_id
    )

    supplemental_claim.start_review!
    [supplemental_claim, intake]
  end

  it "Allows a Veteran without ratings to create an intake" do
    start_supplemental_claim(veteran_no_ratings)

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

    expect(page).to have_content("Request for #{Constants.INTAKE_FORM_NAMES.supplemental_claim} has been processed.")
  end

  context "For new Add Issues page" do
    def check_row(label, text)
      row = find("tr", text: label)
      expect(row).to have_text(text)
    end

    let!(:timely_ratings) do
      Generators::Rating.build(
        participant_id: veteran.participant_id,
        promulgation_date: receipt_date - 40.days,
        profile_date: receipt_date - 50.days,
        issues: [
          { reference_id: "xyz123", decision_text: "Left knee granted" },
          { reference_id: "xyz456", decision_text: "PTSD denied" }
        ]
      )
    end

    scenario "SC comp" do
      supplemental_claim, = start_supplemental_claim(veteran)
      visit "/intake/add_issues"

      expect(page).to have_content("Add Issues")
      check_row("Form", Constants.INTAKE_FORM_NAMES.supplemental_claim)
      check_row("Benefit type", "Compensation")
      check_row("Claimant", "Ed Merica")

      # clicking the add issues button should bring up the modal
      safe_click "#button-add-issue"
      expect(page).to have_content("Add issue 1")
      expect(page).to have_content("Does issue 1 match any of these issues")
      expect(page).to have_content("Left knee granted")
      expect(page).to have_content("PTSD denied")

      # test canceling adding an issue by closing the modal
      safe_click ".close-modal"
      expect(page).to_not have_content("Left knee granted")

      # adding an issue should show the issue
      safe_click "#button-add-issue"
      find_all("label", text: "Left knee granted").first.click
      safe_click ".add-issue"

      expect(page).to have_content("1. Left knee granted")
      expect(page).to_not have_content("Notes:")
      safe_click ".remove-issue"

      expect(page).not_to have_content("Left knee granted")

      # re-add to proceed
      safe_click "#button-add-issue"
      find_all("label", text: "Left knee granted").first.click
      fill_in "Notes", with: "I am an issue note"
      safe_click ".add-issue"

      expect(page).to have_content("1. Left knee granted")
      expect(page).to have_content("I am an issue note")

      # clicking add issue again should show a disabled radio button for that same rating
      safe_click "#button-add-issue"
      expect(page).to have_content("Add issue 2")
      expect(page).to have_content("Does issue 2 match any of these issues")
      expect(page).to have_content("Left knee granted (already selected for issue 1)")
      expect(page).to have_css("input[disabled][id='rating-radio_xyz123']", visible: false)

      # Add non-rated issue
      safe_click ".no-matching-issues"
      expect(page).to have_content("Does issue 2 match any of these issue categories?")
      expect(page).to have_button("Add this issue", disabled: true)
      fill_in "Issue category", with: "Active Duty Adjustments"
      find("#issue-category").send_keys :enter
      fill_in "Issue description", with: "Description for Active Duty Adjustments"
      fill_in "Decision date", with: "04/25/2018"
      expect(page).to have_button("Add this issue", disabled: false)
      safe_click ".add-issue"
      expect(page).to have_content("2 issues")

      # add unidentified issue
      safe_click "#button-add-issue"
      safe_click ".no-matching-issues"
      safe_click ".no-matching-issues"
      expect(page).to have_content("Describe the issue to mark it as needing further review.")
      fill_in "Transcribe the issue as it's written on the form", with: "This is an unidentified issue"
      safe_click ".add-issue"
      expect(page).to have_content("3 issues")
      expect(page).to have_content("This is an unidentified issue")

      safe_click "#button-finish-intake"

      expect(page).to have_content("Request for #{Constants.INTAKE_FORM_NAMES.supplemental_claim} has been processed.")

      expect(page).to have_content(
        "Established EP: 040SCR - Supplemental Claim Rating for Station 499"
      )

      expect(SupplementalClaim.find_by(
               id: supplemental_claim.id,
               veteran_file_number: veteran.file_number,
               establishment_submitted_at: Time.zone.now,
               establishment_processed_at: Time.zone.now,
               establishment_error: nil
      )).to_not be_nil

      end_product_establishment = EndProductEstablishment.find_by(
        source: supplemental_claim,
        veteran_file_number: veteran.file_number,
        code: "040SCR",
        claimant_participant_id: "901987"
      )
      expect(end_product_establishment).to_not be_nil

      non_rating_end_product_establishment = EndProductEstablishment.find_by(
        source: supplemental_claim,
        veteran_file_number: veteran.file_number,
        code: "040SCNR",
        claimant_participant_id: "901987"
      )
      expect(non_rating_end_product_establishment).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: supplemental_claim,
               rating_issue_reference_id: "xyz123",
               description: "Left knee granted",
               end_product_establishment_id: end_product_establishment.id,
               notes: "I am an issue note"
      )).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: supplemental_claim,
               issue_category: "Active Duty Adjustments",
               description: "Description for Active Duty Adjustments",
               decision_date: 1.month.ago.to_date,
               end_product_establishment_id: non_rating_end_product_establishment.id
      )).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: supplemental_claim,
               description: "This is an unidentified issue",
               is_unidentified: true,
               end_product_establishment_id: end_product_establishment.id
      )).to_not be_nil
    end

    scenario "Non-compensation" do
      start_supplemental_claim(veteran, is_comp: false)
      visit "/intake/add_issues"

      expect(page).to have_content("Add Issues")
      check_row("Form", Constants.INTAKE_FORM_NAMES.supplemental_claim)
      check_row("Benefit type", "Education")
      expect(page).to_not have_content("Claimant")
    end

    scenario "canceling" do
      _, intake = start_supplemental_claim(veteran)
      visit "/intake/add_issues"

      expect(page).to have_content("Add Issues")
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
  end
end
