# frozen_string_literal: true

feature "Higher-Level Review", :all_dbs do
  include IntakeHelpers

  before do
    Timecop.freeze(post_ama_start_date)

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
    allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
  end

  let(:ineligible_constants) { Constants.INELIGIBLE_REQUEST_ISSUES }

  let(:veteran_file_number) { "123412345" }

  let(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number,
                              first_name: "Ed",
                              last_name: "Merica")
  end

  let(:veteran_no_ratings) do
    Generators::Veteran.build(file_number: "55555555",
                              first_name: "Nora",
                              last_name: "Attings",
                              participant_id: "44444444")
  end

  let(:inaccessible) { false }

  let(:receipt_date) { Time.zone.today - 5.days }
  let(:promulgation_date) { receipt_date - 10.days }
  let(:benefit_type) { "compensation" }
  let(:untimely_days) { 372.days }

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:profile_date) { (receipt_date - 8.days).to_datetime }
  let(:untimely_promulgation_date) { receipt_date - untimely_days - 1.day }
  let(:untimely_profile_date) { receipt_date - untimely_days - 3.days }
  let(:future_rating_promulgation_date) { receipt_date + 2.days }
  let(:future_rating_profile_date) { receipt_date + 2.days }

  let!(:rating) { generate_rating(veteran, promulgation_date, profile_date) }
  let!(:untimely_ratings) { generate_untimely_rating(veteran, untimely_promulgation_date, untimely_profile_date) }
  let!(:future_rating) { generate_future_rating(veteran, future_rating_promulgation_date, future_rating_profile_date) }
  let!(:before_ama_rating) { generate_pre_ama_rating(veteran) }
  before { FeatureToggle.enable!(:filed_by_va_gov_hlr) }
  after { FeatureToggle.disable!(:filed_by_va_gov_hlr) }
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
    select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
    safe_click ".cf-submit.usa-button"

    expect(page).to have_content(search_page_title)

    fill_in search_bar_title, with: veteran_file_number

    click_on "Search"

    expect(page).to have_current_path("/intake/review_request")

    click_intake_continue

    expect(page).to have_content(
      "What is the Benefit Type?\nPlease select an option."
    )
    expect(page).to have_content(
      "Was this form submitted through VA.gov?"
    )
    expect(page).to have_content(
      "Was an informal conference requested?\nPlease select an option."
    )
    expect(page).to have_content(
      "Was an interview by the same office requested?\nPlease select an option."
    )
    expect(page).to have_content(
      "Is the claimant someone other than the Veteran?\nPlease select an option."
    )
    expect(page).to have_content(
      "Did the Veteran check the \"OPT-IN from SOC/SSOC\" box on the form?\nPlease select an option."
    )

    within_fieldset("Was this form submitted through VA.gov?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    within_fieldset("What is the Benefit Type?") do
      find("label", text: "Insurance", match: :prefer_exact).click
    end

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

    # We do not need to select payee codes for non-VBMS business lines
    expect(page).to_not have_content("What is the payee code for this claimant?")

    # Switch the benefit type to compensation to test choosing the payee code.
    within_fieldset("What is the Benefit Type?") do
      find("label", text: "Compensation", match: :prefer_exact).click
    end

    expect(page).to have_content("What is the payee code for this claimant?")
    expect(page).to have_content("Bob Vance, Spouse")
    expect(page).to_not have_content("Cathy Smith, Child")

    click_intake_continue

    # uncomment this test when when caseflow-1285 is resolved
    # expect(page).to have_content(
    #   "If the claimant is a Veteran's dependant (spouse, child, or parent) and they are not listed"
    # )
    expect(page).to have_content(
      "Please select an option.\nBob Vance, Spouse"
    )

    find("label", text: "Bob Vance, Spouse", match: :prefer_exact).click

    fill_in "What is the payee code for this claimant?", with: "10 - Spouse"
    find("#cf-payee-code").send_keys :enter

    select_agree_to_withdraw_legacy_issues(false)

    fill_in "What is the Receipt Date of this form?", with: Time.zone.tomorrow.mdY

    click_intake_continue

    expect(page).to have_content(
      "Receipt date cannot be in the future."
    )

    fill_in "What is the Receipt Date of this form?", with: receipt_date.mdY

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
    expect(higher_level_review.filed_by_va_gov).to eq(true)
    expect(higher_level_review.benefit_type).to eq(benefit_type)
    expect(higher_level_review.informal_conference).to eq(true)
    expect(higher_level_review.same_office).to eq(false)
    expect(higher_level_review.legacy_opt_in_approved).to eq(false)
    expect(higher_level_review.claimant).to have_attributes(
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
      date: profile_date.mdY
    )

    expect(page).to have_content("2 issues")

    click_intake_finish

    expect(page).to have_content("Request for #{Constants.INTAKE_FORM_NAMES.higher_level_review} has been submitted.")
    expect(page).to have_content("It may take up to 24 hours for the claim to establish")
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
          station_of_jurisdiction: current_user.station_id,
          date: higher_level_review.receipt_date.to_date,
          end_product_modifier: "033",
          end_product_label: "Higher-Level Review Rating",
          end_product_code: "030HLRR",
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
      code: "030HLRR"
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
        station_of_jurisdiction: current_user.station_id,
        date: higher_level_review.receipt_date.to_date,
        end_product_modifier: "032",
        end_product_label: "Higher-Level Review Nonrating",
        end_product_code: "030HLRNR",
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false
      ),
      veteran_hash: intake.veteran.to_vbms_hash,
      user: current_user
    )

    nonratings_end_product_establishment = EndProductEstablishment.find_by(
      source: intake.detail,
      code: "030HLRNR"
    )

    expect(nonratings_end_product_establishment).to have_attributes(
      claimant_participant_id: "5382910292",
      payee_code: "10"
    )

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      hash_including(
        veteran_file_number: veteran_file_number,
        claim_id: ratings_end_product_establishment.reference_id,
        contentions: array_including(description: "PTSD denied",
                                     contention_type: Constants.CONTENTION_TYPES.higher_level_review),
        user: current_user,
        claim_date: higher_level_review.receipt_date.to_date
      )
    )

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      hash_including(
        veteran_file_number: veteran_file_number,
        claim_id: nonratings_end_product_establishment.reference_id,
        contentions: [{ description: "Active Duty Adjustments - Description for Active Duty Adjustments",
                        contention_type: Constants.CONTENTION_TYPES.higher_level_review }],
        user: current_user,
        claim_date: higher_level_review.receipt_date.to_date
      )
    )

    rating_request_issue = higher_level_review.request_issues.find_by(
      contested_issue_description: "PTSD denied"
    )

    expect(rating_request_issue).to have_attributes(benefit_type: "compensation")

    expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).with(
      claim_id: ratings_end_product_establishment.reference_id,
      rating_issue_contention_map: {
        rating_request_issue.contested_rating_issue_reference_id => rating_request_issue.contention_reference_id
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
      contested_rating_issue_reference_id: "def456",
      contested_rating_issue_profile_date: profile_date.to_s,
      contested_issue_description: "PTSD denied",
      decision_date: promulgation_date,
      rating_issue_associated_at: Time.zone.now
    )

    expect(higher_level_review.request_issues.last).to have_attributes(
      contested_rating_issue_reference_id: nil,
      contested_rating_issue_profile_date: nil,
      nonrating_issue_category: "Active Duty Adjustments",
      nonrating_issue_description: "Description for Active Duty Adjustments",
      decision_date: profile_date
    )

    # skip the sync call since all edit requests require resyncing
    # currently, we're not mocking out vbms and bgs
    allow_any_instance_of(EndProductEstablishment).to receive(:sync!).and_return(nil)
    visit "/higher_level_reviews/#{ratings_end_product_establishment.reference_id}/edit"

    expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
    expect(page).to have_content("Ed Merica (#{veteran_file_number})")
    expect(page).to have_content(receipt_date.mdY)
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
    select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
    safe_click ".cf-submit.usa-button"
    fill_in search_bar_title, with: veteran_file_number
    click_on "Search"

    within_fieldset("What is the Benefit Type?") do
      find("label", text: "Compensation", match: :prefer_exact).click
    end

    fill_in "What is the Receipt Date of this form?", with: receipt_date.mdY

    within_fieldset("Was an informal conference requested?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    within_fieldset("Was an interview by the same office requested?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    select_agree_to_withdraw_legacy_issues(false)

    click_intake_continue
    expect(page).to have_current_path("/intake/add_issues")

    higher_level_review = HigherLevelReview.find_by(veteran_file_number: veteran_file_number)
    expect(higher_level_review.same_office).to eq(true)

    click_intake_add_issue
    add_intake_rating_issue("PTSD denied")

    click_intake_finish

    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.higher_level_review} has been submitted.")

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      veteran_file_number: veteran_file_number,
      claim_id: special_issue_reference_id,
      contentions: [{ description: "PTSD denied",
                      contention_type: Constants.CONTENTION_TYPES.higher_level_review,
                      special_issues: [{ code: "SSR", narrative: "Same Station Review" }] }],
      user: current_user,
      claim_date: higher_level_review.receipt_date.to_date
    )
  end

  context "when disabling claim establishment is enabled" do
    before { FeatureToggle.enable!(:disable_claim_establishment) }
    after { FeatureToggle.disable!(:disable_claim_establishment) }

    it "completes intake and prevents edit" do
      start_higher_level_review(veteran_no_ratings)
      visit "/intake"
      click_intake_continue
      click_intake_add_issue
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "Description for Active Duty Adjustments",
        date: profile_date.mdY
      )
      click_intake_finish

      expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.higher_level_review} has been submitted.")

      click_on "correct the issues"

      expect(page).to have_content("Review not editable")
    end
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

  # this version is slightly different from what is in IntakeHelpers
  # TODO it would be good to reconcile and save some duplication.
  def start_higher_level_review(
    test_veteran,
    is_comp: true,
    claim_participant_id: nil,
    legacy_opt_in_approved: false
  )

    higher_level_review = HigherLevelReview.create!(
      veteran_file_number: test_veteran.file_number,
      receipt_date: receipt_date,
      informal_conference: false, same_office: false,
      benefit_type: is_comp ? "compensation" : "education",
      legacy_opt_in_approved: legacy_opt_in_approved,
      veteran_is_not_claimant: claim_participant_id.present?
    )

    intake = HigherLevelReviewIntake.create!(
      veteran_file_number: test_veteran.file_number,
      user: current_user, started_at: 5.minutes.ago,
      detail: higher_level_review
    )

    claimant_class = claim_participant_id.present? ? DependentClaimant : VeteranClaimant
    participant_id = claim_participant_id || test_veteran.participant_id
    claimant_class.create!(
      decision_review: higher_level_review,
      participant_id: participant_id,
      payee_code: claim_participant_id.present? ? "02" : "00"
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
      date: profile_date.mdY
    )

    expect(page).to have_content("1 issue")

    click_intake_finish

    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.higher_level_review} has been submitted.")
  end

  def complete_higher_level_review
    start_higher_level_review(veteran_no_ratings)

    visit "/intake"
    click_intake_continue
    click_intake_add_issue

    # expect the rating modal to be skipped
    expect(page).to have_content("Does issue 1 match any of these non-rating issue categories?")
    add_intake_nonrating_issue(
      category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      date: profile_date.mdY
    )

    click_intake_finish
    expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.higher_level_review} has been submitted.")
  end

  scenario "intake can still be completed when ratings are backfilled" do
    mock_backfilled_rating_response
    complete_higher_level_review
  end

  scenario "intake can still be completed when ratings are locked" do
    mock_locked_rating_response
    complete_higher_level_review
  end

  context "ratings with disabiliity codes" do
    let(:disabiliity_receive_date) { receipt_date + 2.days }
    let(:disability_profile_date) { profile_date - 1.day }
    let!(:ratings_with_diagnostic_codes) do
      generate_ratings_with_disabilities(
        veteran,
        disabiliity_receive_date,
        disability_profile_date
      )
    end

    scenario "saves diagnostic codes" do
      hlr, = start_higher_level_review(veteran)
      visit "/intake"
      click_intake_continue
      save_and_check_request_issues_with_diagnostic_codes(
        Constants.INTAKE_FORM_NAMES.higher_level_review,
        hlr
      )
    end
  end

  context "Add / Remove Issues page" do
    before { FeatureToggle.enable!(:contestable_rating_decisions) }
    after { FeatureToggle.disable!(:contestable_rating_decisions) }

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
      Generators::PromulgatedRating.build(
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

    let!(:untimely_rating) { generate_untimely_rating_from_ramp(veteran, receipt_date, old_reference_id) }
    let!(:before_ama_rating_from_ramp) { generate_rating_before_ama_from_ramp(veteran) }
    let!(:rating_with_old_decisions) { generate_rating_with_old_decisions(veteran, receipt_date) }
    let(:old_rating_decision_text) { "Bone (Right arm broken) is denied." }

    let!(:request_issue_in_progress) do
      create(
        :request_issue,
        end_product_establishment: active_epe,
        contested_rating_issue_reference_id: duplicate_reference_id,
        contested_issue_description: "Old injury"
      )
    end

    let(:previous_higher_level_review) { create(:higher_level_review, veteran_file_number: veteran.file_number) }
    let!(:previous_request_issue) do
      create(
        :request_issue,
        decision_review: previous_higher_level_review,
        contested_rating_issue_reference_id: higher_level_review_reference_id,
        contention_reference_id: contention_reference_id,
        closed_at: 2.months.ago
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
        decision_review: previous_supplemental_claim,
        contested_rating_issue_reference_id: supplemental_claim_reference_id,
        contention_reference_id: supplemental_claim_contention_reference_id
      )
    end

    let!(:decision_issue) do
      create(:decision_issue,
             decision_review: previous_supplemental_claim,
             request_issues: [previous_sc_request_issue],
             rating_issue_reference_id: "resultingscissue123",
             participant_id: veteran.participant_id,
             rating_promulgation_date: another_promulgation_date,
             decision_text: "supplemental claim decision issue",
             rating_profile_date: profile_date,
             end_product_last_action_date: profile_date,
             benefit_type: previous_supplemental_claim.benefit_type)
    end

    context "Veteran has no ratings" do
      let(:decision_date) { (receipt_date + 9000.days).to_date.mdY }

      scenario "the Add Issue modal skips directly to Nonrating Issue modal" do
        start_higher_level_review(veteran_no_ratings)
        visit "/intake/add_issues"

        click_intake_add_issue

        add_intake_nonrating_issue(
          category: "Active Duty Adjustments",
          description: "Description for Active Duty Adjustments",
          date: profile_date.mdY
        )

        expect(page).to have_content("1 issue")
      end

      scenario "validate decision date" do
        start_higher_level_review(veteran_no_ratings)
        visit "/intake/add_issues"
        click_intake_add_issue

        fill_in "Issue category", with: "Apportionment"
        find("#issue-category").send_keys :enter

        fill_in "Decision date", with: decision_date
        expect(page).to have_content("Decision date cannot be in the future")
      end
    end

    context "Veteran with future ratings" do
      before { FeatureToggle.enable!(:show_future_ratings) }
      after { FeatureToggle.disable!(:show_future_ratings) }

      scenario "when show_future_ratings featuretoggle is enabled " do
        higher_level_review, = start_higher_level_review(veteran)
        visit "/intake/add_issues"
        click_intake_add_issue
        expect(page).to have_content("Future rating issue 1")
        expect(higher_level_review.receipt_date).to eq(receipt_date)
      end
    end

    scenario "Add Issues modal uses promulgation date" do
      start_higher_level_review(veteran)
      visit "/intake/add_issues"
      click_intake_add_issue
      rating_date = promulgation_date.mdY

      expect(page).to have_content("Past decisions from #{rating_date}")
    end

    scenario "compensation claim" do
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
      check_row("SOC/SSOC Opt-in", "No")

      # clicking the add issues button should bring up the modal
      click_intake_add_issue

      expect(page).to have_content("Add issue 1")
      expect(page).to have_content("Does issue 1 match any of these issues")
      expect(page).to have_content("Left knee granted")
      expect(page).to have_content("PTSD denied")
      expect(page).to have_content("Old injury")
      expect(page).to have_content("supplemental claim decision issue")
      expect(page).to_not have_content("Future rating issue 1")
      expect(page).to have_content(old_rating_decision_text)

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
      expect(page.has_no_content?("Left knee granted 2")).to eq(true)

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
        date: profile_date.mdY
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
      expect(page).to have_content("5. Really old injury #{ineligible_constants.untimely}")

      # add untimely nonrating request issue
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "Another Description for Active Duty Adjustments",
        date: "04/19/2016"
      )
      add_untimely_exemption_response("No")
      expect(page).to have_content("6 issues")
      expect(page).to have_content(
        "Another Description for Active Duty Adjustments #{ineligible_constants.untimely}"
      )

      # add prior reviewed issue
      click_intake_add_issue
      add_intake_rating_issue("Already reviewed injury")
      expect(page).to have_content("7 issues")
      expect(page).to have_content(
        "7. Already reviewed injury #{ineligible_constants.higher_level_review_to_higher_level_review}"
      )

      # add before_ama ratings
      click_intake_add_issue
      add_intake_rating_issue("Non-RAMP Issue before AMA Activation")
      add_untimely_exemption_response("Yes")
      expect(page).to have_content(
        "8. Non-RAMP Issue before AMA Activation #{ineligible_constants.before_ama}"
      )

      # Eligible because it comes from a RAMP decision
      click_intake_add_issue
      add_intake_rating_issue("Issue before AMA Activation from RAMP")
      add_untimely_exemption_response("Yes")
      expect(page).to have_content(
        "9. Issue before AMA Activation from RAMP\nDecision date:"
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
        date: pre_ramp_start_date.to_date.mdY
      )
      add_untimely_exemption_response("Yes")
      expect(page).to have_content(
        "A nonrating issue before AMA #{ineligible_constants.before_ama}"
      )

      # add old rating decision
      click_intake_add_issue
      add_intake_rating_issue(old_rating_decision_text)
      add_untimely_exemption_response("Yes")
      expect(page).to have_content("#{old_rating_decision_text} #{ineligible_constants.before_ama}")

      click_intake_finish

      expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.higher_level_review} has been submitted.")
      expect(page).to have_content(RequestIssue::UNIDENTIFIED_ISSUE_MSG)
      expect(page).to have_content('Unidentified issue: no issue matched for requested "This is an unidentified issue"')
      success_checklist = find("ul.cf-success-checklist")
      expect(success_checklist).to_not have_content("Already reviewed injury")
      expect(success_checklist).to_not have_content("Another Description for Active Duty Adjustments")

      ineligible_checklist = find("ul.cf-issue-checklist")
      expect(ineligible_checklist).to have_content("Already reviewed injury is ineligible")
      expect(ineligible_checklist).to have_content("Another Description for Active Duty Adjustments is ineligible")
      expect(ineligible_checklist).to have_content(old_rating_decision_text)

      # make sure that database is populated
      expect(
        HigherLevelReview.find_by(
          id: higher_level_review.id,
          veteran_file_number: veteran.file_number,
          establishment_submitted_at: Time.zone.now,
          establishment_processed_at: Time.zone.now,
          establishment_error: nil
        )
      ).to_not be_nil

      end_product_establishment = EndProductEstablishment.find_by(
        source: higher_level_review,
        veteran_file_number: veteran.file_number,
        code: "030HLRR",
        claimant_participant_id: "5382910292",
        payee_code: "02",
        station: current_user.station_id
      )

      expect(end_product_establishment).to_not be_nil

      non_rating_end_product_establishment = EndProductEstablishment.find_by(
        source: higher_level_review,
        veteran_file_number: veteran.file_number,
        code: "030HLRNR",
        claimant_participant_id: "5382910292",
        payee_code: "02",
        station: current_user.station_id
      )
      expect(non_rating_end_product_establishment).to_not be_nil

      # make sure request issue is contesting decision issue
      expect(
        RequestIssue.find_by(
          decision_review: higher_level_review,
          contested_decision_issue_id: decision_issue.id,
          contested_issue_description: "supplemental claim decision issue",
          end_product_establishment_id: end_product_establishment.id,
          notes: "decision issue with note",
          benefit_type: "compensation"
        )
      ).to_not be_nil

      expect(
        RequestIssue.find_by(
          decision_review: higher_level_review,
          contested_rating_issue_reference_id: "xyz123",
          contested_issue_description: "Left knee granted 2",
          end_product_establishment_id: end_product_establishment.id,
          notes: "I am an issue note",
          benefit_type: "compensation"
        )
      ).to_not be_nil

      expect(
        RequestIssue.find_by(
          decision_review: higher_level_review,
          contested_issue_description: "Really old injury",
          end_product_establishment_id: nil,
          untimely_exemption: false,
          benefit_type: "compensation",
          ineligible_reason: "untimely",
          closed_status: :ineligible
        )
      ).to_not be_nil

      active_duty_adjustments_request_issue = RequestIssue.find_by!(
        decision_review: higher_level_review,
        nonrating_issue_category: "Active Duty Adjustments",
        nonrating_issue_description: "Description for Active Duty Adjustments",
        decision_date: profile_date,
        end_product_establishment_id: non_rating_end_product_establishment.id,
        benefit_type: "compensation"
      )

      expect(active_duty_adjustments_request_issue.untimely?).to eq(false)

      another_active_duty_adjustments_request_issue = RequestIssue.find_by!(
        decision_review: higher_level_review,
        nonrating_issue_category: "Active Duty Adjustments",
        nonrating_issue_description: "Another Description for Active Duty Adjustments",
        benefit_type: "compensation"
      )

      expect(another_active_duty_adjustments_request_issue.untimely?).to eq(true)
      expect(another_active_duty_adjustments_request_issue.untimely_exemption?).to eq(false)
      expect(another_active_duty_adjustments_request_issue.untimely_exemption_notes).to_not be_nil

      expect(RequestIssue.find_by(
               decision_review: higher_level_review,
               unidentified_issue_text: "This is an unidentified issue",
               is_unidentified: true,
               end_product_establishment_id: end_product_establishment.id,
               benefit_type: "compensation"
             )).to_not be_nil

      # Issues before AMA
      expect(RequestIssue.find_by(
               decision_review: higher_level_review,
               contested_issue_description: "Non-RAMP Issue before AMA Activation",
               end_product_establishment_id: nil,
               ineligible_reason: :before_ama,
               closed_status: :ineligible,
               benefit_type: "compensation"
             )).to_not be_nil

      expect(RequestIssue.find_by(
               decision_review: higher_level_review,
               contested_issue_description: "Issue before AMA Activation from RAMP",
               ineligible_reason: nil,
               ramp_claim_id: "ramp_claim_id",
               end_product_establishment_id: end_product_establishment.id,
               benefit_type: "compensation"
             )).to_not be_nil

      expect(RequestIssue.find_by(
               decision_review: higher_level_review,
               nonrating_issue_description: "A nonrating issue before AMA",
               ineligible_reason: :before_ama,
               closed_status: :ineligible,
               end_product_establishment_id: nil,
               benefit_type: "compensation"
             )).to_not be_nil

      duplicate_request_issues = RequestIssue.where(contested_rating_issue_reference_id: duplicate_reference_id)
      expect(duplicate_request_issues.count).to eq(2)

      ineligible_issue = duplicate_request_issues.detect(&:duplicate_of_rating_issue_in_active_review?)
      expect(duplicate_request_issues).to include(request_issue_in_progress)
      expect(ineligible_issue).to_not eq(request_issue_in_progress)
      expect(ineligible_issue.contention_reference_id).to be_nil

      expect(RequestIssue.find_by(contested_rating_issue_reference_id: old_reference_id).untimely?).to eq(true)

      hlr_request_issues = RequestIssue.where(contested_rating_issue_reference_id: higher_level_review_reference_id)
      expect(hlr_request_issues.count).to eq(2)

      ineligible_due_to_previous_hlr = hlr_request_issues.detect(&:higher_level_review_to_higher_level_review?)
      expect(hlr_request_issues).to include(previous_request_issue)
      expect(ineligible_due_to_previous_hlr).to_not eq(previous_request_issue)
      expect(ineligible_due_to_previous_hlr.contention_reference_id).to be_nil
      expect(ineligible_due_to_previous_hlr.ineligible_due_to).to eq(previous_request_issue)

      old_rating_decision_request_issue = RequestIssue.find_by(
        decision_review: higher_level_review,
        contested_issue_description: old_rating_decision_text
      )

      expect(old_rating_decision_request_issue.contested_rating_decision_reference_id).to_not be_nil
      expect(old_rating_decision_request_issue).to be_before_ama

      expect(Fakes::VBMSService).to_not have_received(:create_contentions!).with(
        hash_including(
          contentions: array_including(
            { description: "Old injury" },
            { description: "Really old injury" },
            description: "Already reviewed injury"
          )
        )
      )

      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        hash_including(
          contentions: array_including(description: "Left knee granted 2",
                                       contention_type: Constants.CONTENTION_TYPES.higher_level_review)
        )
      )
    end

    context "when veteran chooses decision issue from a previous appeal" do
      let(:previous_appeal) { create(:appeal, :outcoded, veteran: veteran) }
      let(:appeal_reference_id) { "appeal123" }
      let!(:previous_appeal_request_issue) do
        create(
          :request_issue,
          decision_review: previous_appeal,
          contested_rating_issue_reference_id: appeal_reference_id,
          closed_at: 2.months.ago
        )
      end
      let!(:previous_appeal_decision_issue) do
        create(:decision_issue,
               decision_review: previous_appeal,
               request_issues: [previous_appeal_request_issue],
               rating_issue_reference_id: appeal_reference_id,
               participant_id: veteran.participant_id,
               description: "appeal decision issue",
               decision_text: "appeal decision issue",
               benefit_type: "compensation",
               caseflow_decision_date: profile_date)
      end

      scenario "the issue is ineligible" do
        start_higher_level_review(veteran)
        visit "/intake/add_issues"

        expect(page).to have_content("Add / Remove Issues")

        click_intake_add_issue
        add_intake_rating_issue("appeal decision issue")
        expect(page).to have_content(
          "appeal decision issue #{ineligible_constants.appeal_to_higher_level_review}"
        )
        click_intake_finish

        expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.higher_level_review} has been submitted.")

        expect(
          RequestIssue.find_by(contested_issue_description: "appeal decision issue").ineligible_reason
        ).to eq("appeal_to_higher_level_review")

        ineligible_checklist = find("ul.cf-issue-checklist")
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
               decision_review: another_higher_level_review)
      end

      scenario "shows ineligibility message and saves conflicting request issue id" do
        hlr, = start_higher_level_review(veteran)
        visit "/intake/add_issues"
        click_intake_add_issue
        click_intake_no_matching_issues

        fill_in "Issue category", with: active_nonrating_request_issue.nonrating_issue_category
        find("#issue-category").send_keys :enter
        expect(page).to have_content("Does issue 1 match any of the issues actively being reviewed?")
        expect(page).to have_content("#{active_nonrating_request_issue.nonrating_issue_category}: " \
                                     "#{active_nonrating_request_issue.description}")
        add_active_intake_nonrating_issue(active_nonrating_request_issue.nonrating_issue_category)
        expect(page).to have_content("#{active_nonrating_request_issue.nonrating_issue_category} -" \
                                     " #{active_nonrating_request_issue.description}" \
                                     " is ineligible because it's already under review as a Higher-Level Review")

        click_intake_finish
        expect(page).to have_content("Intake completed")
        expect(RequestIssue.find_by(decision_review: hlr,
                                    nonrating_issue_category: active_nonrating_request_issue.nonrating_issue_category,
                                    ineligible_due_to: active_nonrating_request_issue.id,
                                    ineligible_reason: "duplicate_of_nonrating_issue_in_active_review",
                                    nonrating_issue_description: active_nonrating_request_issue.description,
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
                 caseflow_decision_date: receipt_date - 1.day,
                 benefit_type: hlr.benefit_type,
                 decision_text: "something was decided in the past",
                 participant_id: veteran.participant_id)
          create(:decision_issue,
                 decision_review: hlr,
                 caseflow_decision_date: receipt_date + 1.day,
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
        let!(:business_line) { create(:business_line, name: "Education", url: "education") }

        scenario "no rating issues show on first Add Issues modal" do
          hlr, = start_higher_level_review(veteran, is_comp: false)
          expect(OrganizationsUser.existing_record(current_user, Organization.find_by(url: "education"))).to be_nil
          visit "/intake/add_issues"

          expect(page).to have_content("Add / Remove Issues")
          check_row("Form", Constants.INTAKE_FORM_NAMES.higher_level_review)
          check_row("Benefit type", "Education")
          expect(page).to have_content("Claimant")
          click_intake_add_issue
          expect(page).to_not have_content("Left knee granted")

          add_intake_nonrating_issue(
            category: "Accrued",
            description: "I am a description",
            date: profile_date.mdY
          )
          expect(page).to_not have_content("Establish EP")
          expect(page).to have_content("Establish Higher-Level Review")

          click_intake_finish

          # should redirect to tasks review page
          expect(page).to have_content("Reviews needing action")
          expect(page).not_to have_content("It may take up to 24 hours for the claim to establish")
          expect(current_path).to eq("/decision_reviews/education")
          expect(OrganizationsUser.existing_record(current_user, Organization.find_by(url: "education"))).to_not be_nil
          expect(page).to have_content("Success!")

          # request issue should have matching benefit type
          expect(RequestIssue.find_by(
                   decision_review: hlr,
                   nonrating_issue_category: "Accrued",
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

          check_row("SOC/SSOC Opt-in", "Yes")

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
          select_intake_no_match
          add_untimely_exemption_response("Yes")

          expect(page).to have_content("Untimely rating issue 1")

          click_intake_add_issue
          click_intake_no_matching_issues
          add_intake_nonrating_issue(
            category: "Active Duty Adjustments",
            description: "Description for Active Duty Adjustments",
            date: (profile_date - untimely_days).mdY,
            legacy_issues: true
          )

          expect(page).to have_content("Does issue 3 match any of these VACOLS issues?")

          select_intake_no_match
          add_untimely_exemption_response("Yes")

          expect(page).to have_content("Description for Active Duty Adjustments")

          # add eligible legacy issue
          click_intake_add_issue
          add_intake_rating_issue("PTSD denied")
          add_intake_rating_issue("ankylosis of hip")

          expect(page).to have_content(
            "#{COPY::VACOLS_OPTIN_ISSUE_NEW}:\nService connection, ankylosis of hip"
          )

          click_intake_add_issue
          add_intake_rating_issue("Left knee granted 2")

          # these two legacy issues are already selected for other issues
          expect(page).to have_field("ankylosis of hip", disabled: true, visible: false)
          expect(page).to have_field("intervertebral disc syndrome", disabled: true, visible: false)
          click_on("Cancel adding this issue")

          # add before_ama ratings
          click_intake_add_issue
          add_intake_rating_issue("Non-RAMP Issue before AMA Activation")
          add_intake_rating_issue("limitation of thigh motion (extension)")

          expect(page).to have_content("Non-RAMP Issue before AMA Activation")
          expect(page).to_not have_content(
            "Non-RAMP Issue before AMA Activation #{ineligible_constants.before_ama}"
          )

          # add ineligible legacy issue (already opted-in)
          click_intake_add_issue
          add_intake_rating_issue("Looks like a VACOLS issue")
          add_intake_rating_issue("impairment of femur")

          expect(page).to have_content(
            "Looks like a VACOLS issue #{ineligible_constants.legacy_appeal_not_eligible}"
          )

          click_intake_finish

          ineligible_checklist = find("ul.cf-issue-checklist")
          expect(ineligible_checklist).to have_content(
            "Left knee granted #{ineligible_constants.legacy_appeal_not_eligible}"
          )

          expect(RequestIssue.find_by(
                   contested_issue_description: "Left knee granted",
                   ineligible_reason: :legacy_appeal_not_eligible,
                   vacols_id: "vacols2",
                   vacols_sequence_id: "1"
                 )).to_not be_nil

          expect(page).to have_content(COPY::VACOLS_OPTIN_ISSUE_CLOSED)

          expect(LegacyIssueOptin.all.count).to eq(2)

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

        scenario "vacols issues closed" do
          start_higher_level_review(veteran, legacy_opt_in_approved: true)
          visit "/intake/add_issues"

          click_intake_add_issue
          expect(page).to have_content("Next")
          add_intake_rating_issue(/Left knee granted$/)

          add_intake_rating_issue("Service connection, limitation of thigh motion (extension)")
          expect(page).to have_content(
            "#{COPY::VACOLS_OPTIN_ISSUE_NEW}:\nService connection, limitation of thigh motion (extension)"
          )

          click_intake_finish

          # confirmation page shows vacols issue closed
          expect(page).to have_content("VACOLS issue has been closed")
          expect(page).to have_content("Service connection, limitation of thigh motion (extension)")

          # Go to edit page
          click_on "correct the issues"

          expect(page).to have_content(
            "#{COPY::VACOLS_OPTIN_ISSUE_CLOSED_EDIT}:\nService connection, limitation of thigh motion (extension)"
          )

          click_intake_add_issue
          expect(page).to have_content("Next")
          add_intake_rating_issue("Looks like a VACOLS issue")
          add_intake_rating_issue("Service connection, ankylosis of hip")

          expect(page).to have_content(
            "#{COPY::VACOLS_OPTIN_ISSUE_NEW}:\nService connection, ankylosis of hip"
          )

          safe_click("#button-submit-update")
          safe_click ".confirm"
          expect(page).to have_content("Claim Issues Saved")
          expect(page).to have_content("Contention: Looks like a VACOLS issue")
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

          ineligible_checklist = find("ul.cf-issue-checklist")
          expect(ineligible_checklist).to have_content(
            "Left knee granted #{ineligible_constants.legacy_issue_not_withdrawn}"
          )

          expect(RequestIssue.find_by(
                   contested_issue_description: "Left knee granted",
                   ineligible_reason: :legacy_issue_not_withdrawn,
                   vacols_id: "vacols1",
                   vacols_sequence_id: "1"
                 )).to_not be_nil

          expect(page).to_not have_content(COPY::VACOLS_OPTIN_ISSUE_CLOSED)
        end
      end
    end
  end

  context "has a chain of prior decision issues" do
    let(:start_date) { Time.zone.today - 300.days }
    before do
      prior_hlr = create(:higher_level_review, veteran_file_number: veteran.file_number)
      request_issue = create(:request_issue,
                             contested_rating_issue_reference_id: "old123",
                             contested_rating_issue_profile_date: untimely_ratings.profile_date,
                             decision_review: prior_hlr)
      setup_prior_decision_issue_chain(prior_hlr, request_issue, veteran, start_date)
    end

    it "disables prior contestable issues" do
      start_higher_level_review(veteran)
      check_decision_issue_chain(start_date)
    end
  end
end
