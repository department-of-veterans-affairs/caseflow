require "rails_helper"

RSpec.feature "Higher-Level Review" do
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

  it "Creates an end product and contentions for it" do
    # Testing one relationship, tests 2 relationships in HRL and nil in Appeal
    allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
      first_name: "BOB",
      last_name: "VANCE",
      ptcpnt_id: "5382910292",
      relationship_type: "Spouse"
    )

    Generators::EndProduct.build(
      veteran_file_number: "12341234",
      bgs_attrs: { end_product_type_code: "030" }
    )

    Generators::EndProduct.build(
      veteran_file_number: "12341234",
      bgs_attrs: { end_product_type_code: "031" }
    )

    visit "/intake"
    safe_click ".Select"

    fill_in "Which form are you processing?", with: "Request for Higher-Level Review (VA Form 20-0988)"
    find("#form-select").send_keys :enter

    safe_click ".cf-submit.usa-button"

    expect(page).to have_content("Higher-Level Review (VA Form 20-0988)")

    fill_in "Search small", with: "12341234"

    click_on "Search"

    expect(page).to have_current_path("/intake/review_request")

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

    expect(page).to_not have_content("Please select the claimant listed on the form.")
    expect(page).to_not have_content("What is the payee code for this claimant?")
    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    expect(page).to have_content("Please select the claimant listed on the form.")
    expect(page).to have_content("What is the payee code for this claimant?")
    expect(page).to have_content("Bob Vance, Spouse")
    expect(page).to_not have_content("Cathy Smith, Child")

    find("label", text: "Bob Vance, Spouse", match: :prefer_exact).click

    fill_in "What is the payee code for this claimant?", with: "10 - Spouse"
    find("#cf-payee-code").send_keys :enter

    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")

    visit "/intake/review_request"

    within_fieldset("Did the Veteran request an informal conference?") do
      expect(find_field("Yes", visible: false)).to be_checked
    end

    within_fieldset("Did the Veteran request review by the same office?") do
      expect(find_field("No", visible: false)).to be_checked
    end

    expect(find("#different-claimant-option_true", visible: false)).to be_checked
    expect(find_field("Bob Vance, Spouse", visible: false)).to be_checked

    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")

    expect(page).to have_content("Identify issues on")
    expect(page).to have_content("Decision date: 04/17/2017")
    expect(page).to have_content("Left knee granted")
    expect(page).to_not have_content("Untimely rating issue 1")
    expect(page).to have_button("Establish EP", disabled: true)
    expect(page).to have_content("0 issues")

    higher_level_review = HigherLevelReview.find_by(veteran_file_number: "12341234")
    expect(higher_level_review).to_not be_nil
    expect(higher_level_review.receipt_date).to eq(receipt_date)
    expect(higher_level_review.informal_conference).to eq(true)
    expect(higher_level_review.same_office).to eq(false)
    expect(higher_level_review.claimants.first).to have_attributes(
      participant_id: "5382910292",
      payee_code: "10"
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

    expect(page).to have_content("Request for Higher-Level Review (VA Form 20-0988) has been processed.")
    expect(page).to have_content(
      "Established EP: 030HLRR - Higher-Level Review Rating for Station 397 - ARC"
    )

    # ratings end product
    expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
      claim_hash: {
        benefit_type_code: "1",
        payee_code: "10",
        predischarge: false,
        claim_type: "Claim",
        station_of_jurisdiction: "397",
        date: higher_level_review.receipt_date.to_date,
        end_product_modifier: "033",
        end_product_label: "Higher-Level Review Rating",
        end_product_code: HigherLevelReview::END_PRODUCT_RATING_CODE,
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false,
        claimant_participant_id: "5382910292"
      },
      veteran_hash: intake.veteran.to_vbms_hash
    )

    ratings_end_product_establishment = EndProductEstablishment.find_by(
      source: intake.detail,
      code: HigherLevelReview::END_PRODUCT_RATING_CODE
    )

    expect(ratings_end_product_establishment).to have_attributes(
      claimant_participant_id: "5382910292",
      payee_code: "10"
    )

    # nonratings end product
    expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
      claim_hash: hash_including(
        benefit_type_code: "1",
        payee_code: "10",
        predischarge: false,
        claim_type: "Claim",
        station_of_jurisdiction: "397",
        date: higher_level_review.receipt_date.to_date,
        end_product_modifier: "032",
        end_product_label: "Higher-Level Review Nonrating",
        end_product_code: HigherLevelReview::END_PRODUCT_NONRATING_CODE,
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false
      ),
      veteran_hash: intake.veteran.to_vbms_hash
    )

    nonratings_end_product_establishment = EndProductEstablishment.find_by(
      source: intake.detail,
      code: HigherLevelReview::END_PRODUCT_NONRATING_CODE
    )

    expect(nonratings_end_product_establishment).to have_attributes(
      claimant_participant_id: "5382910292",
      payee_code: "10"
    )

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      hash_including(
        veteran_file_number: "12341234",
        claim_id: ratings_end_product_establishment.reference_id,
        contention_descriptions: ["PTSD denied"],
        special_issues: []
      )
    )

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      hash_including(
        veteran_file_number: "12341234",
        claim_id: nonratings_end_product_establishment.reference_id,
        contention_descriptions: ["Description for Active Duty Adjustments"],
        special_issues: []
      )
    )

    rated_issue = higher_level_review.request_issues.find_by(description: "PTSD denied")

    expect(Fakes::VBMSService).to have_received(:associate_rated_issues!).with(
      claim_id: ratings_end_product_establishment.reference_id,
      rated_issue_contention_map: {
        rated_issue.rating_issue_reference_id => rated_issue.contention_reference_id
      }
    )

    intake.reload
    expect(intake.completed_at).to eq(Time.zone.now)

    expect(intake).to be_success

    expect(higher_level_review.request_issues.count).to eq 2
    expect(higher_level_review.request_issues.first).to have_attributes(
      rating_issue_reference_id: "def456",
      rating_issue_profile_date: receipt_date - untimely_days + 4.days,
      description: "PTSD denied",
      decision_date: nil,
      rating_issue_associated_at: Time.zone.now
    )

    expect(higher_level_review.request_issues.last).to have_attributes(
      rating_issue_reference_id: nil,
      rating_issue_profile_date: nil,
      issue_category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      decision_date: 1.month.ago.to_date
    )

    visit "/higher_level_reviews/#{ratings_end_product_establishment.reference_id}/edit"
    expect(page).to have_content("Request for Higher-Level Review (VA Form 20-0988)")
    expect(page).to have_content("Ed Merica (12341234)")
    expect(page).to have_content("04/20/2018")
    expect(find("#table-row-3")).to have_content("Yes")
    expect(find("#table-row-4")).to have_content("No")
    expect(page).to have_content("PTSD denied")

    safe_click ".cf-edit-issues-link"

    expect(page).to have_current_path(
      "/higher_level_reviews/#{ratings_end_product_establishment.reference_id}/edit/select_issues"
    )

    visit "/higher_level_reviews/4321/edit"
    expect(page).to have_content("Page not found")
  end

  it "Creates contentions with same office special issue" do
    Fakes::VBMSService.end_product_claim_id = "IAMANEPID"

    visit "/intake"
    safe_click ".Select"

    fill_in "Which form are you processing?", with: "Request for Higher-Level Review (VA Form 20-0988)"
    find("#form-select").send_keys :enter

    safe_click ".cf-submit.usa-button"

    fill_in "Search small", with: "12341234"

    click_on "Search"

    fill_in "What is the Receipt Date of this form?", with: "04/20/2018"

    within_fieldset("Did the Veteran request an informal conference?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    within_fieldset("Did the Veteran request review by the same office?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")
    expect(page).to have_content("Identify issues on")

    higher_level_review = HigherLevelReview.find_by(veteran_file_number: "12341234")
    expect(higher_level_review.same_office).to eq(true)

    find("label", text: "PTSD denied").click

    safe_click "#button-finish-intake"

    expect(page).to have_content("Request for Higher-Level Review (VA Form 20-0988) has been processed.")

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      veteran_file_number: "12341234",
      claim_id: "IAMANEPID",
      contention_descriptions: ["PTSD denied"],
      special_issues: [{ code: "SSR", narrative: "Same Station Review" }]
    )
  end

  it "Shows a review error when something goes wrong" do
    intake = HigherLevelReviewIntake.new(veteran_file_number: "12341234", user: current_user)
    intake.start!

    visit "/intake"

    fill_in "What is the Receipt Date of this form?", with: "05/28/2018"
    safe_click "#button-submit-review"

    fill_in "What is the Receipt Date of this form?", with: "04/20/2018"

    within_fieldset("Did the Veteran request an informal conference?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    within_fieldset("Did the Veteran request review by the same office?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    ## Validate error message when complete intake fails
    expect_any_instance_of(HigherLevelReviewIntake).to receive(:review!).and_raise("A random error. Oh no!")

    safe_click "#button-submit-review"

    expect(page).to have_content("Something went wrong")
    expect(page).to have_current_path("/intake/review_request")
  end

  it "Allows a Veteran without ratings to create an intake" do
    higher_level_review = HigherLevelReview.create!(
      veteran_file_number: veteran_no_ratings.file_number,
      receipt_date: 2.days.ago,
      informal_conference: false,
      same_office: false
    )

    HigherLevelReviewIntake.create!(
      veteran_file_number: veteran_no_ratings.file_number,
      user: current_user,
      started_at: 5.minutes.ago,
      detail: higher_level_review
    )

    Claimant.create!(
      review_request: higher_level_review,
      participant_id: veteran_no_ratings.participant_id,
      payee_code: "00"
    )

    higher_level_review.start_review!

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

    expect(page).to have_content("Request for Higher-Level Review (VA Form 20-0988) has been processed.")
  end
end
