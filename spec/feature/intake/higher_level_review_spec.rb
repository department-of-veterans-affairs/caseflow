require "support/intake_helpers"

feature "Higher-Level Review" do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)
    FeatureToggle.enable!(:intake_legacy_opt_in)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 11, 28))

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
    allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
  end

  after do
    FeatureToggle.disable!(:intakeAma)
    FeatureToggle.disable!(:intake_legacy_opt_in)
  end

  let(:ineligible_constants) { Constants.INELIGIBLE_REQUEST_ISSUES }
  let(:intake_constants) { Constants.INTAKE_STRINGS }

  let(:veteran_file_number) { "123412345" }

  let(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number, first_name: "Ed", last_name: "Merica")
  end

  let(:veteran_no_ratings) do
    Generators::Veteran.build(file_number: "55555555",
                              first_name: "Nora",
                              last_name: "Attings",
                              participant_id: "44444444")
  end

  let(:inaccessible) { false }

  let(:receipt_date) { Date.new(2018, 9, 20) }

  let(:benefit_type) { "compensation" }

  let(:untimely_days) { 372.days }

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:profile_date) { Time.zone.local(2018, 9, 15) }

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - 5.days,
      profile_date: profile_date,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" },
        { reference_id: "def789", decision_text: "Looks like a VACOLS issue" }
      ]
    )
  end

  let!(:untimely_ratings) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - untimely_days - 1.day,
      profile_date: receipt_date - untimely_days - 3.days,
      issues: [
        { reference_id: "old123", decision_text: "Untimely rating issue 1" },
        { reference_id: "old456", decision_text: "Untimely rating issue 2" }
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
      veteran_file_number: veteran_file_number,
      bgs_attrs: { end_product_type_code: "030" }
    )

    Generators::EndProduct.build(
      veteran_file_number: veteran_file_number,
      bgs_attrs: { end_product_type_code: "031" }
    )

    visit "/intake"
    safe_click ".Select"

    fill_in "Which form are you processing?", with: Constants.INTAKE_FORM_NAMES.higher_level_review
    find("#form-select").send_keys :enter

    safe_click ".cf-submit.usa-button"

    expect(page).to have_content(search_page_title)

    fill_in search_bar_title, with: veteran_file_number

    click_on "Search"

    expect(page).to have_current_path("/intake/review_request")

    fill_in "What is the Receipt Date of this form?", with: "12/15/2018"
    click_intake_continue

    expect(page).to have_content(
      "Receipt date cannot be in the future."
    )
    expect(page).to have_content(
      "What is the Benefit Type? Please select an option."
    )
    expect(page).to have_content(
      "Was an informal conference requested? Please select an option."
    )
    expect(page).to have_content(
      "Was an interview by the same office requested? Please select an option."
    )
    expect(page).to have_content(
      "Is the claimant someone other than the Veteran? Please select an option."
    )
    expect(page).to have_content(
      "Did they agree to withdraw their issues from the legacy system? Please select an option."
    )

    within_fieldset("What is the Benefit Type?") do
      find("label", text: "Fiduciary", match: :prefer_exact).click
    end

    fill_in "What is the Receipt Date of this form?", with: "09/20/2018"

    within_fieldset("Was an informal conference requested?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    within_fieldset("Was an interview by the same office requested?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    expect(page).to_not have_content("Please select the claimant listed on the form.")
    expect(page).to_not have_content("What is the payee code for this claimant?")
    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    expect(page).to have_content("Please select the claimant listed on the form.")

    # We do not need to select payee codes for fiduciaries
    expect(page).to_not have_content("What is the payee code for this claimant?")

    # Switch the benefit type to compensation to test choosing the payee code.
    within_fieldset("What is the Benefit Type?") do
      find("label", text: "Compensation", match: :prefer_exact).click
    end

    expect(page).to have_content("What is the payee code for this claimant?")
    expect(page).to have_content("Bob Vance, Spouse")
    expect(page).to_not have_content("Cathy Smith, Child")

    click_intake_continue

    expect(page).to have_content(
      "add them in VBMS, then refresh this page. Please select an option."
    )
    expect(page).to have_content(
      "What is the payee code for this claimant? Please select an option."
    )

    find("label", text: "Bob Vance, Spouse", match: :prefer_exact).click

    fill_in "What is the payee code for this claimant?", with: "10 - Spouse"
    find("#cf-payee-code").send_keys :enter

    within_fieldset("Did they agree to withdraw their issues from the legacy system?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    click_intake_continue

    expect(page).to have_current_path("/intake/add_issues")

    visit "/intake/review_request"

    within_fieldset("Was an informal conference requested?") do
      expect(find_field("Yes", visible: false)).to be_checked
    end

    within_fieldset("Was an interview by the same office requested?") do
      expect(find_field("No", visible: false)).to be_checked
    end

    expect(find("#different-claimant-option_true", visible: false)).to be_checked
    expect(find_field("Bob Vance, Spouse", visible: false)).to be_checked
    expect(find("#legacy-opt-in_false", visible: false)).to be_checked

    click_intake_continue

    expect(page).to have_current_path("/intake/add_issues")

    higher_level_review = HigherLevelReview.find_by(veteran_file_number: veteran_file_number)
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

    intake = Intake.find_by(veteran_file_number: veteran_file_number)

    click_intake_add_issue
    add_intake_rating_issue("PTSD denied")
    expect(page).to have_content("1 issue")

    click_intake_add_issue
    add_intake_rating_issue("Left knee granted")
    expect(page).to have_content("2 issues")

    click_remove_intake_issue(2)
    expect(page).to have_content("1 issue")

    click_intake_add_issue
    click_intake_no_matching_issues
    add_intake_nonrating_issue(
      category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      date: "10/27/2018"
    )

    expect(page).to have_content("2 issues")

    click_intake_finish

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
      hash_including(
        claim_hash: hash_including(
          benefit_type_code: "1",
          payee_code: "10",
          predischarge: false,
          claim_type: "Claim",
          station_of_jurisdiction: "499",
          date: higher_level_review.receipt_date.to_date,
          end_product_modifier: "033",
          end_product_label: "Higher-Level Review Rating",
          end_product_code: HigherLevelReview::END_PRODUCT_CODES[:rating],
          gulf_war_registry: false,
          suppress_acknowledgement_letter: false,
          claimant_participant_id: "5382910292"
        ),
        veteran_hash: intake.veteran.to_vbms_hash,
        user: current_user
      )
    )

    ratings_end_product_establishment = EndProductEstablishment.find_by(
      source: intake.detail,
      code: HigherLevelReview::END_PRODUCT_CODES[:rating]
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
        end_product_code: HigherLevelReview::END_PRODUCT_CODES[:nonrating],
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false
      ),
      veteran_hash: intake.veteran.to_vbms_hash,
      user: current_user
    )

    nonratings_end_product_establishment = EndProductEstablishment.find_by(
      source: intake.detail,
      code: HigherLevelReview::END_PRODUCT_CODES[:nonrating]
    )

    expect(nonratings_end_product_establishment).to have_attributes(
      claimant_participant_id: "5382910292",
      payee_code: "10"
    )

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      hash_including(
        veteran_file_number: veteran_file_number,
        claim_id: ratings_end_product_establishment.reference_id,
        contention_descriptions: ["PTSD denied"],
        special_issues: [],
        user: current_user
      )
    )

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      hash_including(
        veteran_file_number: veteran_file_number,
        claim_id: nonratings_end_product_establishment.reference_id,
        contention_descriptions: ["Active Duty Adjustments - Description for Active Duty Adjustments"],
        special_issues: [],
        user: current_user
      )
    )

    rating_request_issue = higher_level_review.request_issues.find_by(description: "PTSD denied")

    expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).with(
      claim_id: ratings_end_product_establishment.reference_id,
      rating_issue_contention_map: {
        rating_request_issue.rating_issue_reference_id => rating_request_issue.contention_reference_id
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

    # skip the sync call since all edit requests require resyncing
    # currently, we're not mocking out vbms and bgs
    allow_any_instance_of(EndProductEstablishment).to receive(:sync!).and_return(nil)
    visit "/higher_level_reviews/#{ratings_end_product_establishment.reference_id}/edit"

    expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
    expect(page).to have_content("Ed Merica (#{veteran_file_number})")
    expect(page).to have_content("09/20/2018")
    expect(find("#table-row-4")).to have_content("Yes")
    expect(find("#table-row-5")).to have_content("No")
    expect(page).to have_content("PTSD denied")

    visit "/higher_level_reviews/4321/edit"
    expect(page).to have_content("Page not found")
  end

  let(:special_issue_reference_id) { "IAMANEPID" }

  it "Creates contentions with same office special issue" do
    Fakes::VBMSService.end_product_claim_id = special_issue_reference_id

    visit "/intake"
    safe_click ".Select"

    fill_in "Which form are you processing?", with: Constants.INTAKE_FORM_NAMES.higher_level_review
    find("#form-select").send_keys :enter

    safe_click ".cf-submit.usa-button"

    fill_in search_bar_title, with: veteran_file_number

    click_on "Search"

    within_fieldset("What is the Benefit Type?") do
      find("label", text: "Compensation", match: :prefer_exact).click
    end

    fill_in "What is the Receipt Date of this form?", with: "04/20/2018"

    within_fieldset("Was an informal conference requested?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    within_fieldset("Was an interview by the same office requested?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    within_fieldset("Did they agree to withdraw their issues from the legacy system?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    click_intake_continue
    expect(page).to have_current_path("/intake/add_issues")

    higher_level_review = HigherLevelReview.find_by(veteran_file_number: veteran_file_number)
    expect(higher_level_review.same_office).to eq(true)

    click_intake_add_issue
    add_intake_rating_issue("PTSD denied")

    click_intake_finish

    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.higher_level_review} has been processed.")

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      veteran_file_number: veteran_file_number,
      claim_id: special_issue_reference_id,
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

    click_intake_continue

    expect(page).to have_content("Something went wrong")
    expect(page).to have_current_path("/intake/review_request")
  end

  def start_higher_level_review(
    test_veteran,
    is_comp: true,
    claim_participant_id: nil,
    legacy_opt_in_approved: false,
    veteran_is_not_claimant: false
  )

    higher_level_review = HigherLevelReview.create!(
      veteran_file_number: test_veteran.file_number,
      receipt_date: receipt_date,
      informal_conference: false, same_office: false,
      benefit_type: is_comp ? "compensation" : "education",
      legacy_opt_in_approved: legacy_opt_in_approved,
      veteran_is_not_claimant: veteran_is_not_claimant
    )

    intake = HigherLevelReviewIntake.create!(
      veteran_file_number: test_veteran.file_number,
      user: current_user, started_at: 5.minutes.ago,
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

    click_intake_continue
    click_intake_add_issue
    add_intake_nonrating_issue(
      category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      date: "04/19/2018"
    )

    expect(page).to have_content("1 issue")

    click_intake_finish

    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.higher_level_review} has been processed.")
  end

  context "Add / Remove Issues page" do
    def check_row(label, text)
      row = find("tr", text: label)
      expect(row).to have_text(text)
    end

    let(:higher_level_review_reference_id) { "hlr123" }
    let(:supplemental_claim_reference_id) { "sc123" }
    let(:supplemental_claim_contention_reference_id) { 5678 }
    let(:contention_reference_id) { 1234 }
    let(:duplicate_reference_id) { "xyz789" }
    let(:old_reference_id) { "old1234" }

    let(:active_epe) { create(:end_product_establishment, :active) }

    let(:another_promulgation_date) { receipt_date - 4.days }
    let(:another_profile_date) { receipt_date - 50.days }

    let!(:another_rating) do
      Generators::Rating.build(
        participant_id: veteran.participant_id,
        promulgation_date: another_promulgation_date,
        profile_date: another_profile_date,
        issues: [
          { reference_id: "xyz123", decision_text: "Left knee granted 2" },
          { reference_id: "xyz456", decision_text: "PTSD denied 2" },
          { reference_id: supplemental_claim_reference_id,
            decision_text: "to be replaced by decision issue",
            contention_reference_id: supplemental_claim_contention_reference_id },
          { reference_id: duplicate_reference_id, decision_text: "Old injury" },
          {
            reference_id: higher_level_review_reference_id,
            decision_text: "Already reviewed injury",
            contention_reference_id: contention_reference_id
          }
        ]
      )
    end

    let!(:untimely_rating) do
      Generators::Rating.build(
        participant_id: veteran.participant_id,
        promulgation_date: receipt_date - 400.days,
        profile_date: receipt_date - 450.days,
        issues: [
          { reference_id: old_reference_id, decision_text: "Really old injury" }
        ]
      )
    end

    let!(:before_ama_rating) do
      Generators::Rating.build(
        participant_id: veteran.participant_id,
        promulgation_date: DecisionReview.ama_activation_date - 5.days,
        profile_date: DecisionReview.ama_activation_date - 10.days,
        issues: [
          { reference_id: "before_ama_ref_id", decision_text: "Non-RAMP Issue before AMA Activation" }
        ]
      )
    end

    let!(:before_ama_rating_from_ramp) do
      Generators::Rating.build(
        participant_id: veteran.participant_id,
        promulgation_date: DecisionReview.ama_activation_date - 5.days,
        profile_date: DecisionReview.ama_activation_date - 11.days,
        issues: [
          { decision_text: "Issue before AMA Activation from RAMP",
            reference_id: "ramp_ref_id" }
        ],
        associated_claims: { bnft_clm_tc: "683SCRRRAMP", clm_id: "ramp_claim_id" }
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

    let(:previous_supplemental_claim) do
      create(:supplemental_claim,
             veteran_file_number: veteran.file_number,
             benefit_type: "compensation")
    end

    let!(:previous_sc_request_issue) do
      create(
        :request_issue,
        review_request: previous_supplemental_claim,
        rating_issue_reference_id: supplemental_claim_reference_id,
        contention_reference_id: supplemental_claim_contention_reference_id
      )
    end

    let!(:decision_issue) do
      create(:decision_issue,
             decision_review: previous_supplemental_claim,
             request_issues: [previous_sc_request_issue],
             rating_issue_reference_id: supplemental_claim_reference_id,
             participant_id: veteran.participant_id,
             promulgation_date: another_promulgation_date,
             decision_text: "supplemental claim decision issue",
             profile_date: profile_date,
             benefit_type: previous_supplemental_claim.benefit_type)
    end

    context "Veteran has no ratings" do
      scenario "the Add Issue modal skips directly to Nonrating Issue modal" do
        start_higher_level_review(veteran_no_ratings)
        visit "/intake/add_issues"

        click_intake_add_issue

        add_intake_nonrating_issue(
          category: "Active Duty Adjustments",
          description: "Description for Active Duty Adjustments",
          date: "04/19/2018"
        )

        expect(page).to have_content("1 issue")
      end
    end

    scenario "HLR comp" do
      allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
        first_name: "BOB",
        last_name: "VANCE",
        ptcpnt_id: "5382910292",
        relationship_type: "Spouse"
      )

      higher_level_review, = start_higher_level_review(
        veteran,
        claim_participant_id: "5382910292",
        veteran_is_not_claimant: true
      )
      visit "/intake/add_issues"

      expect(page).to have_content("Add / Remove Issues")
      check_row("Form", Constants.INTAKE_FORM_NAMES.higher_level_review)
      check_row("Benefit type", "Compensation")
      check_row("Claimant", "Bob Vance, Spouse (payee code 02)")

      # clicking the add issues button should bring up the modal
      click_intake_add_issue

      expect(page).to have_content("Add issue 1")
      expect(page).to have_content("Does issue 1 match any of these issues")
      expect(page).to have_content("Left knee granted")
      expect(page).to have_content("PTSD denied")
      expect(page).to have_content("Old injury")
      expect(page).to have_content("supplemental claim decision issue")

      # test canceling adding an issue by closing the modal
      safe_click ".close-modal"
      expect(page).to_not have_content("Left knee granted")

      # adding an issue should show the issue
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted 2")

      expect(page).to have_content("1. Left knee granted")
      expect(page).to_not have_content("Notes:")

      # removing an issue
      click_remove_intake_issue("1")
      expect(page).not_to have_content("Left knee granted 2")

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
        date: "10/27/2018"
      )
      expect(page).to have_content("2 issues")
      # this nonrating request issue is timely
      expect(page).to_not have_content(
        "Description for Active Duty Adjustments #{ineligible_constants.untimely}"
      )

      # add unidentified issue
      click_intake_add_issue
      add_intake_unidentified_issue("This is an unidentified issue")
      expect(page).to have_content("3 issues")
      expect(page).to have_content("This is an unidentified issue")

      # add ineligible issue
      click_intake_add_issue
      add_intake_rating_issue("Old injury")
      expect(page).to have_content("4 issues")
      expect(page).to have_content("4. Old injury is ineligible because it's already under review as a Appeal")

      # add untimely rating request issue
      click_intake_add_issue
      add_intake_rating_issue("Really old injury")
      add_untimely_exemption_response("Yes")

      expect(page).to have_content("5 issues")
      expect(page).to have_content("I am an exemption note")
      expect(page).to_not have_content("5. Really old injury #{ineligible_constants.untimely}")

      # remove and re-add with different answer to exemption
      click_remove_intake_issue("5")
      click_intake_add_issue
      add_intake_rating_issue("Really old injury")
      add_untimely_exemption_response("No")
      expect(page).to have_content("5 issues")
      expect(page).to have_content("I am an exemption note")
      expect(page).to have_content("5. Really old injury #{ineligible_constants.untimely}")

      # add untimely nonrating request issue
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "Another Description for Active Duty Adjustments",
        date: "04/19/2016"
      )
      add_untimely_exemption_response("No", "I am a nonrating exemption note")
      expect(page).to have_content("6 issues")
      expect(page).to have_content("I am a nonrating exemption note")
      expect(page).to have_content(
        "Another Description for Active Duty Adjustments #{ineligible_constants.untimely}"
      )

      # add prior reviewed issue
      click_intake_add_issue
      add_intake_rating_issue("Already reviewed injury")
      expect(page).to have_content("7 issues")
      expect(page).to have_content(
        "7. Already reviewed injury #{ineligible_constants.previous_higher_level_review}"
      )

      # add before_ama ratings
      click_intake_add_issue
      add_intake_rating_issue("Non-RAMP Issue before AMA Activation")
      expect(page).to have_content(
        "8. Non-RAMP Issue before AMA Activation #{ineligible_constants.before_ama}"
      )

      # Eligible because it comes from a RAMP decision
      click_intake_add_issue
      add_intake_rating_issue("Issue before AMA Activation from RAMP")
      expect(page).to have_content(
        "9. Issue before AMA Activation from RAMP Decision date:"
      )

      # Add decision issue
      click_intake_add_issue
      add_intake_rating_issue("supplemental claim decision issue", "decision issue with note")
      expect(page).to have_content("10. supplemental claim decision issue")

      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Drill Pay Adjustments",
        description: "A nonrating issue before AMA",
        date: "10/19/2017"
      )
      expect(page).to have_content(
        "A nonrating issue before AMA #{ineligible_constants.before_ama}"
      )

      click_intake_finish

      expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.higher_level_review} has been processed.")
      expect(page).to have_content(RequestIssue::UNIDENTIFIED_ISSUE_MSG)
      expect(page).to have_content('Unidentified issue: no issue matched for requested "This is an unidentified issue"')
      success_checklist = find("ul.cf-success-checklist")
      expect(success_checklist).to_not have_content("Already reviewed injury")
      expect(success_checklist).to_not have_content("Another Description for Active Duty Adjustments")

      ineligible_checklist = find("ul.cf-ineligible-checklist")
      expect(ineligible_checklist).to have_content("Already reviewed injury is ineligible")
      expect(ineligible_checklist).to have_content("Another Description for Active Duty Adjustments is ineligible")

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

      # make sure request issue is contesting decision issue
      expect(RequestIssue.find_by(
               review_request: higher_level_review,
               contested_decision_issue_id: decision_issue.id,
               description: "supplemental claim decision issue",
               end_product_establishment_id: end_product_establishment.id,
               notes: "decision issue with note",
               benefit_type: "compensation"
      )).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: higher_level_review,
               rating_issue_reference_id: "xyz123",
               description: "Left knee granted 2",
               end_product_establishment_id: end_product_establishment.id,
               notes: "I am an issue note",
               benefit_type: "compensation"
      )).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: higher_level_review,
               description: "Really old injury",
               end_product_establishment_id: end_product_establishment.id,
               untimely_exemption: false,
               untimely_exemption_notes: "I am an exemption note",
               benefit_type: "compensation"
      )).to_not be_nil

      active_duty_adjustments_request_issue = RequestIssue.find_by!(
        review_request: higher_level_review,
        issue_category: "Active Duty Adjustments",
        description: "Description for Active Duty Adjustments",
        decision_date: 1.month.ago,
        end_product_establishment_id: non_rating_end_product_establishment.id,
        benefit_type: "compensation"
      )

      expect(active_duty_adjustments_request_issue.untimely?).to eq(false)

      another_active_duty_adjustments_request_issue = RequestIssue.find_by!(
        review_request: higher_level_review,
        issue_category: "Active Duty Adjustments",
        description: "Another Description for Active Duty Adjustments",
        benefit_type: "compensation"
      )

      expect(another_active_duty_adjustments_request_issue.untimely?).to eq(true)
      expect(another_active_duty_adjustments_request_issue.untimely_exemption?).to eq(false)
      expect(another_active_duty_adjustments_request_issue.untimely_exemption_notes).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: higher_level_review,
               description: "This is an unidentified issue",
               is_unidentified: true,
               end_product_establishment_id: end_product_establishment.id,
               benefit_type: "compensation"
      )).to_not be_nil

      # Issues before AMA
      expect(RequestIssue.find_by(
               review_request: higher_level_review,
               description: "Non-RAMP Issue before AMA Activation",
               end_product_establishment_id: end_product_establishment.id,
               ineligible_reason: :before_ama,
               benefit_type: "compensation"
      )).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: higher_level_review,
               description: "Issue before AMA Activation from RAMP",
               ineligible_reason: nil,
               ramp_claim_id: "ramp_claim_id",
               end_product_establishment_id: end_product_establishment.id,
               benefit_type: "compensation"
      )).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: higher_level_review,
               description: "A nonrating issue before AMA",
               ineligible_reason: :before_ama,
               end_product_establishment_id: non_rating_end_product_establishment.id,
               benefit_type: "compensation"
      )).to_not be_nil

      duplicate_request_issues = RequestIssue.where(rating_issue_reference_id: duplicate_reference_id)
      expect(duplicate_request_issues.count).to eq(2)

      ineligible_issue = duplicate_request_issues.select(&:duplicate_of_rating_issue_in_active_review?).first
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
          contention_descriptions: array_including("Left knee granted 2")
        )
      )
    end

    context "when veteran chooses decision issue from a previous appeal" do
      let(:previous_appeal) { create(:appeal, veteran: veteran) }
      let(:appeal_reference_id) { "appeal123" }
      let!(:previous_appeal_request_issue) do
        create(
          :request_issue,
          review_request: previous_appeal,
          rating_issue_reference_id: appeal_reference_id
        )
      end
      let!(:previous_appeal_decision_issue) do
        create(:decision_issue,
               decision_review: previous_appeal,
               request_issues: [previous_appeal_request_issue],
               rating_issue_reference_id: appeal_reference_id,
               participant_id: veteran.participant_id,
               promulgation_date: another_promulgation_date,
               description: "appeal decision issue",
               decision_text: "appeal decision issue",
               profile_date: profile_date,
               benefit_type: "compensation")
      end

      scenario "the issue is ineligible" do
        start_higher_level_review(
          veteran,
          claim_participant_id: "5382910292",
          veteran_is_not_claimant: false
        )
        visit "/intake/add_issues"

        expect(page).to have_content("Add / Remove Issues")

        click_intake_add_issue
        add_intake_rating_issue("appeal decision issue")
        expect(page).to have_content(
          "appeal decision issue #{ineligible_constants.appeal_to_higher_level_review}"
        )
        click_intake_finish

        expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.higher_level_review} has been processed.")
        expect(RequestIssue.find_by(description: "appeal decision issue").ineligible_reason).to eq(
          "appeal_to_higher_level_review"
        )
        ineligible_checklist = find("ul.cf-ineligible-checklist")
        expect(ineligible_checklist).to have_content(
          "appeal decision issue #{ineligible_constants.appeal_to_higher_level_review}"
        )
      end
    end

    context "when veteran has active nonrating request issues" do
      let(:another_higher_level_review) { create(:higher_level_review) }
      let!(:active_nonrating_request_issue) do
        create(:request_issue_with_epe,
               :nonrating,
               veteran_participant_id: veteran.participant_id,
               review_request: another_higher_level_review)
      end

      scenario "shows ineligibility message and saves conflicting request issue id" do
        hlr, = start_higher_level_review(veteran)
        visit "/intake/add_issues"
        click_intake_add_issue
        click_intake_no_matching_issues

        fill_in "Issue category", with: active_nonrating_request_issue.issue_category
        find("#issue-category").send_keys :enter
        expect(page).to have_content("Does issue 1 match any of the issues actively being reviewed?")
        expect(page).to have_content("#{active_nonrating_request_issue.issue_category}: " \
                                     "#{active_nonrating_request_issue.description}")
        add_active_intake_nonrating_issue(active_nonrating_request_issue.issue_category)
        expect(page).to have_content("#{active_nonrating_request_issue.issue_category} -" \
                                     " #{active_nonrating_request_issue.description}" \
                                     " is ineligible because it's already under review as a Higher-Level Review")

        click_intake_finish
        expect(page).to have_content("Intake completed")
        expect(RequestIssue.find_by(review_request: hlr,
                                    issue_category: active_nonrating_request_issue.issue_category,
                                    ineligible_due_to: active_nonrating_request_issue.id,
                                    ineligible_reason: "duplicate_of_nonrating_issue_in_active_review",
                                    description: active_nonrating_request_issue.description,
                                    decision_date: active_nonrating_request_issue.decision_date)).to_not be_nil
      end
    end

    it "Shows a review error when something goes wrong" do
      start_higher_level_review(veteran)
      visit "/intake/add_issues"

      click_intake_add_issue
      add_intake_rating_issue("Left knee granted", "I am an issue note")

      ## Validate error message when complete intake fails
      expect_any_instance_of(HigherLevelReviewIntake).to receive(:complete!).and_raise("A random error. Oh no!")

      click_intake_finish

      expect(page).to have_content("Something went wrong")
      expect(page).to have_current_path("/intake/add_issues")
    end

    context "Non-compensation" do
      context "decision issues present" do
        scenario "Add Issues button shows contestable issues" do
          hlr, = start_higher_level_review(veteran, is_comp: false)
          create(:decision_issue,
                 decision_review: hlr,
                 profile_date: receipt_date - 1.day,
                 benefit_type: hlr.benefit_type,
                 decision_text: "something was decided in the past",
                 participant_id: veteran.participant_id)
          create(:decision_issue,
                 decision_review: hlr,
                 profile_date: receipt_date + 1.day,
                 benefit_type: hlr.benefit_type,
                 decision_text: "something was decided in the future",
                 participant_id: veteran.participant_id)

          visit "/intake/add_issues"
          click_intake_add_issue

          expect(page).to have_content("something was decided in the past")
          expect(page).to_not have_content("something was decided in the future")
          expect(page).to_not have_content("Left knee granted")
        end
      end

      context "no contestable issues present" do
        scenario "no rating issues show on first Add Issues modal" do
          hlr, = start_higher_level_review(veteran, is_comp: false)
          visit "/intake/add_issues"

          expect(page).to have_content("Add / Remove Issues")
          check_row("Form", Constants.INTAKE_FORM_NAMES.higher_level_review)
          check_row("Benefit type", "Education")
          expect(page).to_not have_content("Claimant")
          click_intake_add_issue
          expect(page).to_not have_content("Left knee granted")

          add_intake_nonrating_issue(
            category: "Accrued",
            description: "I am a description",
            date: "10/25/2017"
          )
          expect(page).to_not have_content("Establish EP")
          expect(page).to have_content("Establish Higher-Level Review")

          click_intake_finish
          expect(page).to have_content("Intake completed")
          # request issue should have matching benefit type
          expect(RequestIssue.find_by(
                   review_request: hlr,
                   issue_category: "Accrued",
                   benefit_type: hlr.benefit_type
          )).to_not be_nil
        end
      end
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

    context "with active legacy appeal" do
      before do
        setup_legacy_opt_in_appeals(veteran.file_number)
      end

      context "with legacy_opt_in_approved" do
        let(:receipt_date) { Time.zone.today }

        scenario "adding issues" do
          start_higher_level_review(veteran, legacy_opt_in_approved: true)
          visit "/intake/add_issues"

          click_intake_add_issue
          expect(page).to have_content("Next")
          add_intake_rating_issue(/Left knee granted$/)

          # expect legacy opt in modal
          expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
          # do not show "inactive and ineligible" issues when legacy opt in is true
          expect(page).to_not have_content("typhoid arthritis")

          add_intake_rating_issue("intervertebral disc syndrome") # ineligible issue

          expect(page).to have_content(
            "Left knee granted #{ineligible_constants.legacy_appeal_not_eligible}"
          )

          # Expect untimely exemption modal for untimely issue
          click_intake_add_issue
          add_intake_rating_issue("Untimely rating issue 1")
          add_intake_rating_issue("None of these match")
          add_untimely_exemption_response("Yes")

          expect(page).to have_content("Untimely rating issue 1")

          click_intake_add_issue
          click_intake_no_matching_issues
          add_intake_nonrating_issue(
            category: "Active Duty Adjustments",
            description: "Description for Active Duty Adjustments",
            date: "10/25/2017",
            legacy_issues: true
          )

          expect(page).to have_content("Does issue 3 match any of these VACOLS issues?")

          add_intake_rating_issue("None of these match")
          add_untimely_exemption_response("Yes")

          expect(page).to have_content("Description for Active Duty Adjustments")

          # add eligible legacy issue
          click_intake_add_issue
          add_intake_rating_issue("PTSD denied")
          add_intake_rating_issue("ankylosis of hip")

          expect(page).to have_content(
            "#{intake_constants.adding_this_issue_vacols_optin}: Service connection, ankylosis of hip"
          )

          # add ineligible legacy issue (already opted-in)
          click_intake_add_issue
          add_intake_rating_issue("Looks like a VACOLS issue")
          add_intake_rating_issue("impairment of femur")

          expect(page).to have_content(
            "Looks like a VACOLS issue #{ineligible_constants.legacy_appeal_not_eligible}"
          )

          click_intake_finish

          ineligible_checklist = find("ul.cf-ineligible-checklist")
          expect(ineligible_checklist).to have_content(
            "Left knee granted #{ineligible_constants.legacy_appeal_not_eligible}"
          )

          expect(RequestIssue.find_by(
                   description: "Left knee granted",
                   ineligible_reason: :legacy_appeal_not_eligible,
                   vacols_id: "vacols2",
                   vacols_sequence_id: "1"
          )).to_not be_nil

          expect(page).to have_content(intake_constants.vacols_optin_issue_closed)

          expect(LegacyIssueOptin.all.count).to eq(1)

          li_optin = LegacyIssueOptin.first

          expect(li_optin.optin_processed_at).to_not be_nil
          expect(li_optin).to have_attributes(
            vacols_id: "vacols1",
            vacols_sequence_id: 1
          )
          expect(VACOLS::CaseIssue.find_by(isskey: "vacols1", issseq: 1).issdc).to eq(
            LegacyIssueOptin::VACOLS_DISPOSITION_CODE
          )
        end
      end

      context "with legacy opt in not approved" do
        scenario "adding issues" do
          start_higher_level_review(veteran, legacy_opt_in_approved: false)
          visit "/intake/add_issues"
          click_intake_add_issue
          add_intake_rating_issue(/^Left knee granted$/)

          expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
          # do not show inactive appeals when legacy opt in is false
          expect(page).to_not have_content("impairment of hip")
          expect(page).to_not have_content("typhoid arthritis")

          add_intake_rating_issue("ankylosis of hip")

          expect(page).to have_content(
            "Left knee granted #{ineligible_constants.legacy_issue_not_withdrawn}"
          )

          click_intake_finish

          ineligible_checklist = find("ul.cf-ineligible-checklist")
          expect(ineligible_checklist).to have_content(
            "Left knee granted #{ineligible_constants.legacy_issue_not_withdrawn}"
          )

          expect(RequestIssue.find_by(
                   description: "Left knee granted",
                   ineligible_reason: :legacy_issue_not_withdrawn,
                   vacols_id: "vacols1",
                   vacols_sequence_id: "1"
          )).to_not be_nil

          expect(page).to_not have_content(intake_constants.vacols_optin_issue_closed)
        end
      end

      scenario "adding issue with legacy opt in disabled" do
        allow(FeatureToggle).to receive(:enabled?).and_call_original
        allow(FeatureToggle).to receive(:enabled?).with(:intake_legacy_opt_in, user: current_user).and_return(false)

        start_higher_level_review(veteran)
        visit "/intake/add_issues"

        click_intake_add_issue
        expect(page).to have_content("Add this issue")
        add_intake_rating_issue(/^Left knee granted$/)
        expect(page).to have_content("Left knee granted")
      end
    end
  end
end
