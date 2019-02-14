require "support/intake_helpers"

feature "Supplemental Claim Intake" do
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

  let(:issues) do
    [
      Generators::Issue.build
    ]
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
        { reference_id: "def456", decision_text: "PTSD denied" }
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

  let!(:future_rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date + 2.days,
      profile_date: receipt_date + 2.days,
      issues: [
        { reference_id: "future1", decision_text: "Future rating issue 1" },
        { reference_id: "future2", decision_text: "Future rating issue 2" }
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
      veteran_file_number: veteran_file_number,
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

    fill_in search_bar_title, with: veteran_file_number

    click_on "Search"

    expect(page).to have_current_path("/intake/review_request")

    within_fieldset("What is the Benefit Type?") do
      find("label", text: "Compensation", match: :prefer_exact).click
    end

    fill_in "What is the Receipt Date of this form?", with: "12/15/2018"
    click_intake_continue
    expect(page).to have_content(
      "Receipt date cannot be in the future."
    )

    fill_in "What is the Receipt Date of this form?", with: "09/20/2018"

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

    select_agree_to_withdraw_legacy_issues(false)

    click_intake_continue

    expect(page).to have_current_path("/intake/add_issues")

    visit "/intake/review_request"

    expect(find("#different-claimant-option_true", visible: false)).to be_checked
    expect(find_field("Baz Qux, Child", visible: false)).to be_checked
    expect(find("#legacy-opt-in_false", visible: false)).to be_checked

    click_intake_continue

    expect(page).to have_current_path("/intake/add_issues")

    supplemental_claim = SupplementalClaim.find_by(veteran_file_number: veteran_file_number)

    expect(supplemental_claim).to_not be_nil
    expect(supplemental_claim.receipt_date).to eq(receipt_date)
    expect(supplemental_claim.benefit_type).to eq(benefit_type)
    expect(supplemental_claim.legacy_opt_in_approved).to eq(false)
    expect(supplemental_claim.claimants.first).to have_attributes(
      participant_id: "5382910293",
      payee_code: "11"
    )
    intake = Intake.find_by(veteran_file_number: veteran_file_number)

    click_intake_add_issue
    expect(page).to_not have_content("Future rating issue 1")
    add_intake_rating_issue("PTSD denied")
    expect(page).to have_content("1 issue")

    click_intake_add_issue
    add_intake_rating_issue("Left knee granted")
    expect(page).to have_content("2 issues")

    click_remove_intake_issue(2)
    expect(page).to have_content("1 issue")
    expect(page).to_not have_content("Left knee granted")

    click_intake_add_issue
    click_intake_no_matching_issues

    add_intake_nonrating_issue(
      category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      date: "10/27/2018"
    )

    expect(page).to have_content("2 issues")

    click_intake_finish

    expect(page).to have_content("Request for #{Constants.INTAKE_FORM_NAMES.supplemental_claim} has been processed.")
    expect(page).to have_content(
      "A #{Constants.INTAKE_FORM_NAMES_SHORT.supplemental_claim} Rating EP is being established:"
    )
    expect(page).to have_content("Contention: PTSD denied")
    expect(page).to have_content(
      "A #{Constants.INTAKE_FORM_NAMES_SHORT.supplemental_claim} Nonrating EP is being established:"
    )
    expect(page).to have_content("Contention: Active Duty Adjustments - Description for Active Duty Adjustments")

    intake.detail.reload

    expect(intake.detail.end_product_establishments.count).to eq(2)

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
        end_product_code: "040SCR",
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false,
        claimant_participant_id: "5382910293"
      },
      veteran_hash: intake.veteran.to_vbms_hash,
      user: current_user
    )

    ratings_end_product_establishment = intake.detail.end_product_establishments.find do |epe|
      epe.code == "040SCR"
    end

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
        end_product_code: "040SCNR",
        gulf_war_registry: false,
        suppress_acknowledgement_letter: false,
        claimant_participant_id: "5382910293"
      },
      veteran_hash: intake.veteran.to_vbms_hash,
      user: current_user
    )

    nonratings_end_product_establishment = intake.detail.end_product_establishments.find do |epe|
      epe.code == "040SCNR"
    end

    expect(nonratings_end_product_establishment).to have_attributes(
      claimant_participant_id: "5382910293",
      payee_code: "11"
    )

    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      veteran_file_number: veteran_file_number,
      claim_id: ratings_end_product_establishment.reference_id,
      contentions: [{ description: "PTSD denied" }],
      user: current_user
    )
    expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
      veteran_file_number: veteran_file_number,
      claim_id: nonratings_end_product_establishment.reference_id,
      contentions: [{ description: "Active Duty Adjustments - Description for Active Duty Adjustments" }],
      user: current_user
    )

    rating_request_issue = supplemental_claim.request_issues.find_by(contested_issue_description: "PTSD denied")

    expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).with(
      claim_id: ratings_end_product_establishment.reference_id,
      rating_issue_contention_map: {
        rating_request_issue.contested_rating_issue_reference_id => rating_request_issue.contention_reference_id
      }
    )

    intake.reload
    expect(intake.completed_at).to eq(Time.zone.now)

    expect(intake).to be_success

    expect(supplemental_claim.request_issues.count).to eq 2
    expect(supplemental_claim.request_issues.first).to have_attributes(
      contested_rating_issue_reference_id: "def456",
      contested_rating_issue_profile_date: profile_date.to_s,
      contested_issue_description: "PTSD denied",
      decision_date: nil,
      rating_issue_associated_at: Time.zone.now
    )
    expect(supplemental_claim.request_issues.last).to have_attributes(
      contested_rating_issue_reference_id: nil,
      contested_rating_issue_profile_date: nil,
      issue_category: "Active Duty Adjustments",
      nonrating_issue_description: "Description for Active Duty Adjustments",
      decision_date: 1.month.ago.to_date
    )

    # skip the sync call since all edit requests require resyncing
    # currently, we're not mocking out vbms and bgs
    allow_any_instance_of(EndProductEstablishment).to receive(:sync!).and_return(nil)
    visit "/supplemental_claims/#{ratings_end_product_establishment.reference_id}/edit"

    expect(page).to have_content(Constants.INTAKE_FORM_NAMES.supplemental_claim)
    expect(page).to have_content("Ed Merica (#{veteran_file_number})")
    expect(page).to have_content("09/20/2018")
    expect(page).to_not have_content("Informal conference request")
    expect(page).to_not have_content("Same office request")
    expect(page).to have_content("PTSD denied")

    visit "/supplemental_claims/4321/edit"
    expect(page).to have_content("Page not found")
  end

  it "Shows a review error when something goes wrong" do
    start_supplemental_claim(veteran_no_ratings)
    visit "/intake"

    ## Validate error message when complete intake fails
    expect_any_instance_of(SupplementalClaimIntake).to receive(:review!).and_raise("A random error. Oh no!")

    click_intake_continue

    expect(page).to have_content("Something went wrong")
    expect(page).to have_current_path("/intake/review_request")
  end

  def start_supplemental_claim(
    test_veteran,
    is_comp: true,
    legacy_opt_in_approved: false,
    veteran_is_not_claimant: false
  )

    supplemental_claim = SupplementalClaim.create!(
      veteran_file_number: test_veteran.file_number,
      receipt_date: receipt_date,
      benefit_type: is_comp ? "compensation" : "education",
      legacy_opt_in_approved: legacy_opt_in_approved,
      veteran_is_not_claimant: veteran_is_not_claimant
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

    click_intake_continue
    click_intake_add_issue
    add_intake_nonrating_issue(
      category: "Active Duty Adjustments",
      description: "Description for Active Duty Adjustments",
      date: "10/27/2018"
    )

    expect(page).to have_content("1 issue")

    click_intake_finish

    expect(page).to have_content("Request for #{Constants.INTAKE_FORM_NAMES.supplemental_claim} has been processed.")
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
      sc, = start_supplemental_claim(veteran)
      visit "/intake"
      click_intake_continue
      save_and_check_request_issues_with_diagnostic_codes(
        Constants.INTAKE_FORM_NAMES.supplemental_claim,
        sc
      )
    end
  end

  context "Add / Remove Issues page" do
    let(:duplicate_reference_id) { "xyz789" }
    let(:old_reference_id) { "old1234" }
    let(:active_epe) { create(:end_product_establishment, :active) }

    let!(:timely_ratings) do
      Generators::Rating.build(
        participant_id: veteran.participant_id,
        promulgation_date: receipt_date - 40.days,
        profile_date: receipt_date - 50.days,
        issues: [
          { reference_id: "xyz123", decision_text: "Left knee granted 2" },
          { reference_id: "xyz456", decision_text: "PTSD denied 2" },
          { reference_id: duplicate_reference_id, decision_text: "Old injury" }
        ]
      )
    end

    let!(:untimely_rating_from_ramp) do
      Generators::Rating.build(
        participant_id: veteran.participant_id,
        promulgation_date: receipt_date - 400.days,
        profile_date: receipt_date - 450.days,
        issues: [
          { reference_id: old_reference_id,
            decision_text: "Really old injury" }
        ],
        associated_claims: { bnft_clm_tc: "683SCRRRAMP", clm_id: "ramp_claim_id" }
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
        contested_rating_issue_reference_id: duplicate_reference_id,
        contested_issue_description: "Old injury"
      )
    end

    context "Veteran has no ratings" do
      scenario "the Add Issue modal skips directly to Nonrating Issue modal" do
        start_supplemental_claim(veteran_no_ratings)
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

    scenario "SC comp" do
      supplemental_claim, = start_supplemental_claim(veteran)
      visit "/intake/add_issues"

      expect(page).to have_content("Add / Remove Issues")
      check_row("Form", Constants.INTAKE_FORM_NAMES.supplemental_claim)
      check_row("Benefit type", "Compensation")
      check_row("Claimant", "Ed Merica")

      # clicking the add issues button should bring up the modal
      click_intake_add_issue
      expect(page).to have_content("Add issue 1")
      expect(page).to have_content("Does issue 1 match any of these issues")
      expect(page).to have_content("Left knee granted 2")
      expect(page).to have_content("PTSD denied 2")
      expect(page).to have_content("Old injury")

      # test canceling adding an issue by closing the modal
      safe_click ".close-modal"
      expect(page).to_not have_content("Left knee granted 2")

      # adding an issue should show the issue
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted 2")
      expect(page).to have_content("1. Left knee granted 2")
      expect(page).to_not have_content("Notes:")

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
      # SC is always timely
      expect(page).to_not have_content("Description for Active Duty Adjustments is ineligible because it has a prior")

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

      # add untimely issue (OK on Supplemental Claim)
      click_intake_add_issue
      add_intake_rating_issue("Really old injury")
      expect(page).to have_content("5 issues")
      expect(page).to have_content("5. Really old injury")
      expect(page).to_not have_content("5. Really old injury #{ineligible_constants.untimely}")

      # add before_ama ratings
      click_intake_add_issue
      add_intake_rating_issue("Non-RAMP Issue before AMA Activation")
      expect(page).to have_content(
        "6. Non-RAMP Issue before AMA Activation #{ineligible_constants.before_ama}"
      )

      # Eligible because it comes from a RAMP decision
      click_intake_add_issue
      add_intake_rating_issue("Issue before AMA Activation from RAMP")
      expect(page).to have_content(
        "7. Issue before AMA Activation from RAMP Decision date:"
      )

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

      expect(page).to have_content("Request for #{Constants.INTAKE_FORM_NAMES.supplemental_claim} has been processed.")
      expect(page).to have_content(RequestIssue::UNIDENTIFIED_ISSUE_MSG)
      expect(page).to have_content('Unidentified issue: no issue matched for requested "This is an unidentified issue"')
      success_checklist = find("ul.cf-success-checklist")
      expect(success_checklist).to_not have_content("Non-RAMP issue before AMA Activation")
      expect(success_checklist).to_not have_content("A nonrating issue before AMA")

      ineligible_checklist = find("ul.cf-ineligible-checklist")
      expect(ineligible_checklist).to have_content("Non-RAMP Issue before AMA Activation is ineligible")
      expect(ineligible_checklist).to have_content("A nonrating issue before AMA is ineligible")

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
        claimant_participant_id: supplemental_claim.claimant_participant_id,
        station: "499"
      )

      expect(end_product_establishment).to_not be_nil

      non_rating_end_product_establishment = EndProductEstablishment.find_by(
        source: supplemental_claim,
        veteran_file_number: veteran.file_number,
        code: "040SCNR",
        claimant_participant_id: supplemental_claim.claimant_participant_id,
        station: "499"
      )
      expect(non_rating_end_product_establishment).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: supplemental_claim,
               contested_rating_issue_reference_id: "xyz123",
               contested_issue_description: "Left knee granted 2",
               end_product_establishment_id: end_product_establishment.id,
               notes: "I am an issue note"
             )).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: supplemental_claim,
               issue_category: "Active Duty Adjustments",
               nonrating_issue_description: "Description for Active Duty Adjustments",
               decision_date: 1.month.ago.to_date,
               end_product_establishment_id: non_rating_end_product_establishment.id
             )).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: supplemental_claim,
               unidentified_issue_text: "This is an unidentified issue",
               is_unidentified: true,
               end_product_establishment_id: end_product_establishment.id
             )).to_not be_nil

      # Issues before AMA
      expect(RequestIssue.find_by(
               review_request: supplemental_claim,
               contested_issue_description: "Non-RAMP Issue before AMA Activation",
               end_product_establishment_id: nil,
               ineligible_reason: :before_ama
             )).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: supplemental_claim,
               contested_issue_description: "Issue before AMA Activation from RAMP",
               ineligible_reason: nil,
               ramp_claim_id: "ramp_claim_id",
               end_product_establishment_id: end_product_establishment.id
             )).to_not be_nil

      expect(RequestIssue.find_by(
               review_request: supplemental_claim,
               nonrating_issue_description: "A nonrating issue before AMA",
               ineligible_reason: :before_ama,
               end_product_establishment_id: nil
             )).to_not be_nil

      duplicate_request_issues = RequestIssue.where(contested_rating_issue_reference_id: duplicate_reference_id)
      expect(duplicate_request_issues.count).to eq(2)

      ineligible_issue = duplicate_request_issues.detect(&:duplicate_of_rating_issue_in_active_review?)
      expect(ineligible_issue).to_not eq(request_issue_in_progress)
      expect(ineligible_issue.contention_reference_id).to be_nil
      expect(RequestIssue.find_by(contested_rating_issue_reference_id: old_reference_id).eligible?).to eq(true)

      expect(Fakes::VBMSService).to_not have_received(:create_contentions!).with(
        hash_including(
          contentions: array_including(description: "Old injury")
        )
      )

      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        hash_including(
          contentions: array_including({ description: "Left knee granted 2" }, description: "Really old injury")
        )
      )
    end

    it "Shows a review error when something goes wrong" do
      start_supplemental_claim(veteran)
      visit "/intake/add_issues"

      click_intake_add_issue
      add_intake_rating_issue("Left knee granted", "I am an issue note")

      ## Validate error message when complete intake fails
      expect_any_instance_of(SupplementalClaimIntake).to receive(:complete!).and_raise("A random error. Oh no!")

      click_intake_finish

      expect(page).to have_content("Something went wrong")
      expect(page).to have_current_path("/intake/add_issues")
    end

    context "Non-compensation" do
      context "decision issues are present" do
        scenario "Add Issues button shows contestable issues" do
          sc, = start_supplemental_claim(veteran, is_comp: false)
          create(:decision_issue,
                 decision_review: sc,
                 caseflow_decision_date: receipt_date - 1.day,
                 benefit_type: sc.benefit_type,
                 decision_text: "something was decided",
                 participant_id: veteran.participant_id)

          visit "/intake/add_issues"
          click_intake_add_issue

          expect(page).to have_content("something was decided")
          expect(page).to_not have_content("Left knee granted")
        end
      end

      context "no contestable issues present" do
        before do
          education_org = create(:business_line, name: "Education", url: "education")
          OrganizationsUser.add_user_to_organization(current_user, education_org)
          FeatureToggle.enable!(:decision_reviews)
        end

        after do
          FeatureToggle.disable!(:decision_reviews)
        end

        scenario "no rating issues show on first Add Issues modal" do
          sc, = start_supplemental_claim(veteran, is_comp: false)

          visit "/intake/add_issues"

          expect(page).to have_content("Add / Remove Issues")
          check_row("Form", Constants.INTAKE_FORM_NAMES.supplemental_claim)
          check_row("Benefit type", "Education")

          expect(page).to_not have_content("Left knee granted")

          click_intake_add_issue
          add_intake_nonrating_issue(
            category: "Accrued",
            description: "I am a description",
            date: "10/25/2017"
          )

          expect(page).to_not have_content("Establish EP")
          expect(page).to have_content("Establish Supplemental Claim")
          expect(page).to_not have_content("Claimant")

          click_intake_finish

          # should redirect to tasks review page
          expect(page).to have_content("Reviews needing action")
          expect(current_path).to eq("/decision_reviews/education")
          expect(page).to have_content("Success!")

          # request issue should have matching benefit type
          expect(RequestIssue.find_by(
                   review_request: sc,
                   issue_category: "Accrued",
                   benefit_type: sc.benefit_type
                 )).to_not be_nil
        end
      end
    end

    scenario "canceling" do
      _, intake = start_supplemental_claim(veteran)
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
          start_supplemental_claim(veteran, legacy_opt_in_approved: true)
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

          expect(page).to have_content("Description for Active Duty Adjustments")

          # add before_ama ratings
          click_intake_add_issue
          add_intake_rating_issue("Non-RAMP Issue before AMA Activation")
          add_intake_rating_issue("limitation of thigh motion (extension)")

          expect(page).to have_content("Non-RAMP Issue before AMA Activation")
          expect(page).to_not have_content(
            "Non-RAMP Issue before AMA Activation #{ineligible_constants.before_ama}"
          )

          # add eligible legacy issue
          click_intake_add_issue
          add_intake_rating_issue("PTSD denied")
          add_intake_rating_issue("ankylosis of hip")

          expect(page).to have_content(
            "#{intake_constants.adding_this_issue_vacols_optin}: Service connection, ankylosis of hip"
          )

          click_intake_finish

          ineligible_checklist = find("ul.cf-ineligible-checklist")
          expect(ineligible_checklist).to have_content(
            "Left knee granted #{ineligible_constants.legacy_appeal_not_eligible}"
          )

          expect(RequestIssue.find_by(
                   contested_issue_description: "Left knee granted",
                   ineligible_reason: :legacy_appeal_not_eligible,
                   vacols_id: "vacols2",
                   vacols_sequence_id: "1"
                 )).to_not be_nil

          expect(page).to have_content(intake_constants.vacols_optin_issue_closed)
        end
      end

      context "with legacy opt in not approved" do
        scenario "adding issues" do
          start_supplemental_claim(veteran, legacy_opt_in_approved: false)
          visit "/intake/add_issues"
          click_intake_add_issue
          add_intake_rating_issue("Left knee granted")

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
                   contested_issue_description: "Left knee granted",
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

        start_supplemental_claim(veteran)
        visit "/intake/add_issues"

        click_intake_add_issue
        expect(page).to have_content("Add this issue")
        add_intake_rating_issue("Left knee granted")
        expect(page).to have_content("Left knee granted")
      end
    end
  end
end
