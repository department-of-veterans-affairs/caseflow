require "rails_helper"

RSpec.feature "Higher-Level Review" do
  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)
    FeatureToggle.enable!(:intake_legacy_opt_in)
    FeatureToggle.enable!(:test_facols)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 26))

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
    allow(Fakes::VBMSService).to receive(:associate_rated_issues!).and_call_original
  end

  after do
    FeatureToggle.disable!(:intakeAma)
    FeatureToggle.disable!(:intake_legacy_opt_in)
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

    fill_in "Which form are you processing?", with: Constants.INTAKE_FORM_NAMES.higher_level_review
    find("#form-select").send_keys :enter

    safe_click ".cf-submit.usa-button"

    expect(page).to have_content(search_page_title)

    fill_in search_bar_title, with: "12341234"

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

    within_fieldset("What is the Benefit Type?") do
      find("label", text: "Compensation", match: :prefer_exact).click
    end

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

    within_fieldset("Did they agree to withdraw their issues from the legacy system?") do
      find("label", text: "No", match: :prefer_exact).click
    end

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
    expect(find("#legacy-opt-in_false", visible: false)).to be_checked

    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")

    expect(page).to have_content("Identify issues on")
    expect(page).to have_content("Decision date: 04/17/2017")
    expect(page).to have_content("Left knee granted")
    expect(page).to have_content("Untimely rating issue 1")
    expect(page).to have_button("Establish EP", disabled: true)
    expect(page).to have_content("0 issues")

    higher_level_review = HigherLevelReview.find_by(veteran_file_number: "12341234")
    expect(higher_level_review).to_not be_nil
    expect(higher_level_review.receipt_date).to eq(receipt_date)
    expect(higher_level_review.benefit_type).to eq(benefit_type)
    expect(higher_level_review.informal_conference).to eq(true)
    expect(higher_level_review.same_office).to eq(false)
    expect(higher_level_review.legacy_opt_in_approved).to eq(false)
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

    expect(page).to have_content("Request for #{Constants.INTAKE_FORM_NAMES.higher_level_review} has been processed.")
    expect(page).to have_content(
      "A #{Constants.INTAKE_FORM_NAMES_SHORT.higher_level_review} Rating EP is being established:"
    )
    expect(page).to have_content("Contention: PTSD denied")
    expect(page).to have_content(
      "A #{Constants.INTAKE_FORM_NAMES_SHORT.higher_level_review} Nonrating EP is being established:"
    )
    expect(page).to have_content("Contention: Active Duty Adjustments - Description for Active Duty Adjustments")
    expect(page).to have_content("Informal Conference Tracked Item")

    # ratings end product
    expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
      claim_hash: {
        benefit_type_code: "1",
        payee_code: "10",
        predischarge: false,
        claim_type: "Claim",
        station_of_jurisdiction: "499",
        date: higher_level_review.receipt_date.to_date,
        end_product_modifier: "033",
        end_product_label: "Higher-Level Review Rating",
        end_product_code: HigherLevelReview::END_PRODUCT_RATING_CODE,
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false,
        claimant_participant_id: "5382910292"
      },
      veteran_hash: intake.veteran.to_vbms_hash,
      user: current_user
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
        station_of_jurisdiction: "499",
        date: higher_level_review.receipt_date.to_date,
        end_product_modifier: "032",
        end_product_label: "Higher-Level Review Nonrating",
        end_product_code: HigherLevelReview::END_PRODUCT_NONRATING_CODE,
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false
      ),
      veteran_hash: intake.veteran.to_vbms_hash,
      user: current_user
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
        special_issues: [],
        user: current_user
      )
    )

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      hash_including(
        veteran_file_number: "12341234",
        claim_id: nonratings_end_product_establishment.reference_id,
        contention_descriptions: ["Active Duty Adjustments - Description for Active Duty Adjustments"],
        special_issues: [],
        user: current_user
      )
    )

    rated_issue = higher_level_review.request_issues.find_by(description: "PTSD denied")

    expect(Fakes::VBMSService).to have_received(:associate_rated_issues!).with(
      claim_id: ratings_end_product_establishment.reference_id,
      rated_issue_contention_map: {
        rated_issue.rating_issue_reference_id => rated_issue.contention_reference_id
      }
    )

    letter_request = Fakes::BGSService.manage_claimant_letter_v2_requests
    expect(letter_request[ratings_end_product_establishment.reference_id]).to eq(
      program_type_cd: "CPL", claimant_participant_id: "5382910292"
    )
    expect(letter_request[nonratings_end_product_establishment.reference_id]).to eq(
      program_type_cd: "CPL", claimant_participant_id: "5382910292"
    )

    tracked_item_request = Fakes::BGSService.generate_tracked_items_requests
    expect(tracked_item_request[ratings_end_product_establishment.reference_id]).to be(true)
    expect(tracked_item_request[nonratings_end_product_establishment.reference_id]).to be(true)

    intake.reload
    expect(intake.completed_at).to eq(Time.zone.now)

    expect(intake).to be_success

    expect(ratings_end_product_establishment.doc_reference_id).to eq("doc_reference_id_result")
    expect(ratings_end_product_establishment.development_item_reference_id).to eq(
      "development_item_reference_id_result"
    )
    expect(ratings_end_product_establishment.benefit_type_code).to eq("1")
    expect(nonratings_end_product_establishment.doc_reference_id).to eq("doc_reference_id_result")
    expect(nonratings_end_product_establishment.development_item_reference_id).to eq(
      "development_item_reference_id_result"
    )
    expect(nonratings_end_product_establishment.benefit_type_code).to eq("1")

    expect(higher_level_review.request_issues.count).to eq 2
    expect(higher_level_review.request_issues.first).to have_attributes(
      rating_issue_reference_id: "def456",
      rating_issue_profile_date: profile_date,
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

    expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
    expect(page).to have_content("Ed Merica (12341234)")
    expect(page).to have_content("04/20/2018")
    expect(find("#table-row-4")).to have_content("Yes")
    expect(find("#table-row-5")).to have_content("No")
    expect(page).to have_content("PTSD denied")

    visit "/higher_level_reviews/4321/edit"
    expect(page).to have_content("Page not found")
  end

  it "Creates contentions with same office special issue" do
    Fakes::VBMSService.end_product_claim_id = "IAMANEPID"

    visit "/intake"
    safe_click ".Select"

    fill_in "Which form are you processing?", with: Constants.INTAKE_FORM_NAMES.higher_level_review
    find("#form-select").send_keys :enter

    safe_click ".cf-submit.usa-button"

    fill_in search_bar_title, with: "12341234"

    click_on "Search"

    within_fieldset("What is the Benefit Type?") do
      find("label", text: "Compensation", match: :prefer_exact).click
    end

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

    within_fieldset("Did they agree to withdraw their issues from the legacy system?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    safe_click "#button-submit-review"

    expect(page).to have_current_path("/intake/finish")
    expect(page).to have_content("Identify issues on")

    higher_level_review = HigherLevelReview.find_by(veteran_file_number: "12341234")
    expect(higher_level_review.same_office).to eq(true)

    find("label", text: "PTSD denied").click

    safe_click "#button-finish-intake"

    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.higher_level_review} has been processed.")

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      veteran_file_number: "12341234",
      claim_id: "IAMANEPID",
      contention_descriptions: ["PTSD denied"],
      special_issues: [{ code: "SSR", narrative: "Same Station Review" }],
      user: current_user
    )
  end

  it "Shows a review error when something goes wrong" do
    start_higher_level_review(veteran_no_ratings)
    visit "/intake"

    ## Validate error message when complete intake fails
    expect_any_instance_of(HigherLevelReviewIntake).to receive(:review!).and_raise("A random error. Oh no!")

    safe_click "#button-submit-review"

    expect(page).to have_content("Something went wrong")
    expect(page).to have_current_path("/intake/review_request")
  end

  def start_higher_level_review(test_veteran, is_comp: true, claim_participant_id: nil)
    higher_level_review = HigherLevelReview.create!(
      veteran_file_number: test_veteran.file_number,
      receipt_date: 2.days.ago,
      informal_conference: false, same_office: false,
      benefit_type: is_comp ? "compensation" : "education",
      legacy_opt_in_approved: false
    )

    intake = HigherLevelReviewIntake.create!(
      veteran_file_number: test_veteran.file_number,
      user: current_user,
      started_at: 5.minutes.ago,
      detail: higher_level_review
    )

    Claimant.create!(
      review_request: higher_level_review,
      participant_id: claim_participant_id ? claim_participant_id : test_veteran.participant_id,
      payee_code: claim_participant_id ? "02" : "00"
    )

    higher_level_review.start_review!

    [higher_level_review, intake]
  end

  it "Allows a Veteran without ratings to create an intake" do
    start_higher_level_review(veteran_no_ratings)

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

    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.higher_level_review} has been processed.")
  end

  scenario "redirects to add_issues with feature flag enabled" do
    FeatureToggle.enable!(:intake_enable_add_issues_page)
    start_higher_level_review(veteran_no_ratings)
    visit "/intake"

    safe_click "#button-submit-review"
    expect(page).to have_current_path("/intake/add_issues")

    FeatureToggle.disable!(:intake_enable_add_issues_page)
  end

  context "For new Add / Remove Issues page" do
    def check_row(label, text)
      row = find("tr", text: label)
      expect(row).to have_text(text)
    end

    let(:higher_level_review_reference_id) { "hlr123" }
    let(:contention_reference_id) { 1234 }
    let(:duplicate_reference_id) { "xyz789" }
    let(:old_reference_id) { "old123" }
    let(:active_epe) { create(:end_product_establishment, :active) }

    let!(:timely_ratings) do
      Generators::Rating.build(
        participant_id: veteran.participant_id,
        promulgation_date: receipt_date - 40.days,
        profile_date: receipt_date - 50.days,
        issues: [
          { reference_id: "xyz123", decision_text: "Left knee granted" },
          { reference_id: "xyz456", decision_text: "PTSD denied" },
          { reference_id: duplicate_reference_id, decision_text: "Old injury" },
          {
            reference_id: higher_level_review_reference_id,
            decision_text: "Already reviewed injury",
            contention_reference_id: contention_reference_id
          }
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
    end

    let!(:request_issue_in_progress) do
      create(
        :request_issue,
        end_product_establishment: active_epe,
        rating_issue_reference_id: duplicate_reference_id,
        description: "Old injury"
      )
    end

    let(:previous_higher_level_review) { create(:higher_level_review, veteran_file_number: veteran.file_number) }
    let!(:previous_request_issue) do
      create(
        :request_issue,
        review_request: previous_higher_level_review,
        rating_issue_reference_id: higher_level_review_reference_id,
        contention_reference_id: contention_reference_id
      )
    end

    scenario "HLR comp" do
      allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
        first_name: "BOB",
        last_name: "VANCE",
        ptcpnt_id: "5382910292",
        relationship_type: "Spouse"
      )

      higher_level_review, = start_higher_level_review(veteran, claim_participant_id: "5382910292")
      visit "/intake/add_issues"

      expect(page).to have_content("Add / Remove Issues")
      check_row("Form", Constants.INTAKE_FORM_NAMES.higher_level_review)
      check_row("Benefit type", "Compensation")
      check_row("Claimant", "Bob Vance, Spouse (payee code 02)")

      # clicking the add issues button should bring up the modal
      safe_click "#button-add-issue"

      expect(page).to have_content("Add issue 1")
      expect(page).to have_content("Does issue 1 match any of these issues")
      expect(page).to have_content("Left knee granted")
      expect(page).to have_content("PTSD denied")
      expect(page).to have_content("Old injury")

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
      # this nonrated issue is timely
      expect(page).to_not have_content(
        "Description for Active Duty Adjustments #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}"
      )

      # add unidentified issue
      safe_click "#button-add-issue"
      safe_click ".no-matching-issues"
      safe_click ".no-matching-issues"
      expect(page).to have_content("Describe the issue to mark it as needing further review.")
      fill_in "Transcribe the issue as it's written on the form", with: "This is an unidentified issue"
      safe_click ".add-issue"
      expect(page).to have_content("3 issues")
      expect(page).to have_content("This is an unidentified issue")

      # add ineligible issue
      safe_click "#button-add-issue"
      find_all("label", text: "Old injury").first.click
      safe_click ".add-issue"
      expect(page).to have_content("4 issues")
      expect(page).to have_content("4. Old injury is ineligible because it's already under review as a Appeal")

      # add untimely rated issue
      safe_click "#button-add-issue"
      find_all("label", text: "Really old injury").first.click
      safe_click ".add-issue"
      expect(page).to have_content("5 issues")
      expect(page).to have_content("5. Really old injury #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}")

      # add untimely nonrated issue
      safe_click "#button-add-issue"
      safe_click ".no-matching-issues"
      expect(page).to have_button("Add this issue", disabled: true)
      fill_in "Issue category", with: "Active Duty Adjustments"
      find("#issue-category").send_keys :enter
      fill_in "Issue description", with: "Another Description for Active Duty Adjustments"
      fill_in "Decision date", with: "04/19/2016"
      expect(page).to have_button("Add this issue", disabled: false)
      safe_click ".add-issue"
      expect(page).to have_content("6 issues")
      expect(page).to have_content(
        "Another Description for Active Duty Adjustments #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}"
      )

      # add prior reviewed issue
      safe_click "#button-add-issue"
      find_all("label", text: "Already reviewed injury").first.click
      safe_click ".add-issue"
      expect(page).to have_content("7 issues")
      expect(page).to have_content(
        "7. Already reviewed injury #{Constants.INELIGIBLE_REQUEST_ISSUES.previous_higher_level_review}"
      )

      safe_click "#button-finish-intake"

      expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.higher_level_review} has been processed.")
      expect(page).to have_content("This is an unidentified issue")

      # make sure that database is populated
      expect(HigherLevelReview.find_by(
               id: higher_level_review.id,
               veteran_file_number: veteran.file_number,
               establishment_submitted_at: Time.zone.now,
               establishment_processed_at: Time.zone.now,
               establishment_error: nil
      )).to_not be_nil

      end_product_establishment = EndProductEstablishment.find_by(
        source: higher_level_review,
        veteran_file_number: veteran.file_number,
        code: "030HLRR",
        claimant_participant_id: "5382910292",
        payee_code: "02",
        station: "499"
      )

      expect(end_product_establishment).to_not be_nil

      non_rating_end_product_establishment = EndProductEstablishment.find_by(
        source: higher_level_review,
        veteran_file_number: veteran.file_number,
        code: "030HLRNR",
        claimant_participant_id: "5382910292",
        payee_code: "02",
        station: "499"
      )
      expect(non_rating_end_product_establishment).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: higher_level_review,
               rating_issue_reference_id: "xyz123",
               description: "Left knee granted",
               end_product_establishment_id: end_product_establishment.id,
               notes: "I am an issue note"
      )).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: higher_level_review,
               issue_category: "Active Duty Adjustments",
               description: "Description for Active Duty Adjustments",
               decision_date: 1.month.ago.to_date,
               end_product_establishment_id: non_rating_end_product_establishment.id
      )).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: higher_level_review,
               description: "This is an unidentified issue",
               is_unidentified: true,
               end_product_establishment_id: end_product_establishment.id
      )).to_not be_nil

      duplicate_request_issues = RequestIssue.where(rating_issue_reference_id: duplicate_reference_id)
      expect(duplicate_request_issues.count).to eq(2)

      ineligible_issue = duplicate_request_issues.select(&:duplicate_of_issue_in_active_review?).first
      expect(duplicate_request_issues).to include(request_issue_in_progress)
      expect(ineligible_issue).to_not eq(request_issue_in_progress)
      expect(ineligible_issue.contention_reference_id).to be_nil

      expect(RequestIssue.find_by(rating_issue_reference_id: old_reference_id).untimely?).to eq(true)

      hlr_request_issues = RequestIssue.where(rating_issue_reference_id: higher_level_review_reference_id)
      expect(hlr_request_issues.count).to eq(2)

      ineligible_due_to_previous_hlr = hlr_request_issues.select(&:previous_higher_level_review?).first
      expect(hlr_request_issues).to include(previous_request_issue)
      expect(ineligible_due_to_previous_hlr).to_not eq(previous_request_issue)
      expect(ineligible_due_to_previous_hlr.contention_reference_id).to be_nil
      expect(ineligible_due_to_previous_hlr.ineligible_due_to).to eq(previous_request_issue)

      expect(Fakes::VBMSService).to_not have_received(:create_contentions!).with(
        hash_including(
          contention_descriptions: array_including("Old injury", "Really old injury", "Already reviewed injury")
        )
      )

      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        hash_including(
          contention_descriptions: array_including("Left knee granted")
        )
      )
    end

    it "Shows a review error when something goes wrong" do
      start_higher_level_review(veteran)
      visit "/intake/add_issues"

      safe_click "#button-add-issue"
      find_all("label", text: "Left knee granted").first.click
      fill_in "Notes", with: "I am an issue note"
      safe_click ".add-issue"

      ## Validate error message when complete intake fails
      expect_any_instance_of(HigherLevelReviewIntake).to receive(:complete!).and_raise("A random error. Oh no!")

      safe_click "#button-finish-intake"

      expect(page).to have_content("Something went wrong")
      expect(page).to have_current_path("/intake/add_issues")
    end

    scenario "Non-compensation" do
      start_higher_level_review(veteran, is_comp: false)
      visit "/intake/add_issues"

      expect(page).to have_content("Add / Remove Issues")
      check_row("Form", Constants.INTAKE_FORM_NAMES.higher_level_review)
      check_row("Benefit type", "Education")
      expect(page).to_not have_content("Claimant")
    end

    scenario "canceling" do
      _, intake = start_higher_level_review(veteran)
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
  end
end
