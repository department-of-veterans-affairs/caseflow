# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module IntakeHelpers
  # rubocop: disable Metrics/ParameterLists
  def blur_from(locator)
    field = find_field(locator)
    field.native.send_keys :tab
  end

  def select_form(form_name)
    if FeatureToggle.enabled?(:ramp_intake)
      safe_click ".cf-select"
      fill_in "Which form are you processing?", with: form_name
      find("#intake-form-select").send_keys :enter
    else
      within_fieldset("Which form are you processing?") do
        find("label", text: form_name).click
      end
    end
  end

  def stub_valid_address
    bgs_record = {
      address_line_1: "address line 1",
      address_line_2: "address line 2",
      address_line_3: "address line 3",
      city: "city"
    }
    allow_any_instance_of(BgsAddressService).to receive(:fetch_bgs_record).and_return(bgs_record)
  end

  def start_higher_level_review(
    test_veteran,
    receipt_date: 1.day.ago,
    claim_participant_id: nil,
    legacy_opt_in_approved: false,
    benefit_type: "compensation",
    informal_conference: false,
    no_claimant: false
  )

    higher_level_review = HigherLevelReview.create!(
      veteran_file_number: test_veteran.file_number,
      receipt_date: receipt_date,
      informal_conference: informal_conference,
      same_office: false,
      benefit_type: benefit_type,
      legacy_opt_in_approved: legacy_opt_in_approved,
      veteran_is_not_claimant: claim_participant_id.present?
    )

    intake = HigherLevelReviewIntake.create!(
      veteran_file_number: test_veteran.file_number,
      user: User.authenticate!(roles: ["Mail Intake"]),
      started_at: 5.minutes.ago,
      detail: higher_level_review
    )

    unless no_claimant
      stub_valid_address
      participant_id = claim_participant_id || test_veteran.participant_id
      payee_code = claim_participant_id ? "02" : "00"
      create(
        :claimant,
        decision_review: higher_level_review,
        participant_id: participant_id,
        payee_code: payee_code
      )
    end

    higher_level_review.start_review!

    [higher_level_review, intake]
  end

  def start_supplemental_claim(
    test_veteran,
    receipt_date: 1.day.ago,
    legacy_opt_in_approved: false,
    claim_participant_id: nil,
    benefit_type: "compensation",
    no_claimant: false
  )

    supplemental_claim = SupplementalClaim.create!(
      veteran_file_number: test_veteran.file_number,
      receipt_date: receipt_date,
      benefit_type: benefit_type,
      legacy_opt_in_approved: legacy_opt_in_approved,
      veteran_is_not_claimant: claim_participant_id.present?
    )

    intake = SupplementalClaimIntake.create!(
      veteran_file_number: test_veteran.file_number,
      user: User.authenticate!(roles: ["Mail Intake"]),
      started_at: 5.minutes.ago,
      detail: supplemental_claim
    )

    unless no_claimant
      stub_valid_address
      participant_id = claim_participant_id || test_veteran.participant_id
      payee_code = claim_participant_id ? "02" : "00"
      claimant_class = claim_participant_id.present? ? DependentClaimant : VeteranClaimant
      claimant_class.create!(
        decision_review: supplemental_claim,
        participant_id: participant_id,
        payee_code: payee_code
      )
    end

    supplemental_claim.start_review!
    [supplemental_claim, intake]
  end

  def start_appeal(
    test_veteran,
    receipt_date: 1.day.ago,
    claim_participant_id: nil,
    legacy_opt_in_approved: false,
    no_claimant: false
  )
    appeal = Appeal.create!(
      veteran_file_number: test_veteran.file_number,
      receipt_date: receipt_date,
      docket_type: Constants.AMA_DOCKETS.evidence_submission,
      legacy_opt_in_approved: legacy_opt_in_approved,
      veteran_is_not_claimant: claim_participant_id.present?
    )

    intake = AppealIntake.create!(
      veteran_file_number: test_veteran.file_number,
      user: User.authenticate!(roles: ["Mail Intake"]),
      started_at: 5.minutes.ago,
      detail: appeal
    )

    unless no_claimant
      stub_valid_address
      participant_id = claim_participant_id || test_veteran.participant_id
      claimant_class = claim_participant_id.present? ? DependentClaimant : VeteranClaimant
      claimant_class.create!(
        decision_review: appeal,
        participant_id: participant_id
      )
    end

    appeal.start_review!

    [appeal, intake]
  end
  # rubocop: enable Metrics/ParameterLists

  def start_claim_review(
    claim_review_type,
    veteran: create(:veteran),
    claim_participant_id: nil,
    benefit_type: "compensation",
    no_claimant: false
  )
    if claim_review_type == :supplemental_claim
      start_supplemental_claim(
        veteran,
        claim_participant_id: claim_participant_id,
        benefit_type: benefit_type,
        no_claimant: no_claimant
      )
    else
      start_higher_level_review(
        veteran,
        claim_participant_id: claim_participant_id,
        informal_conference: true,
        benefit_type: benefit_type,
        no_claimant: no_claimant
      )
    end
  end

  def setup_intake_flags
    Timecop.freeze(Time.zone.today)

    # skip the sync call since all edit requests require resyncing
    # currently, we're not mocking out vbms and bgs
    allow_any_instance_of(EndProductEstablishment).to receive(:sync!).and_return(nil)

    User.authenticate!(roles: ["Admin Intake"])
  end

  def search_page_title
    "Search for Veteran by ID"
  end

  def search_bar_title
    "Enter the Veteran's ID"
  end

  def add_untimely_exemption_response(yes_or_no, note = "I am an exemption note")
    expect(page).to have_content("The issue requested isn't usually eligible because its decision date is older")
    find_all("label", text: yes_or_no).first.click
    fill_in "Notes", with: note if yes_or_no == "Yes"
    safe_click ".add-issue"
  end

  def click_intake_nonrating_category_dropdown
    safe_click ".dropdown-issue-category .cf-select__placeholder"
  end

  def click_intake_add_issue
    safe_click "#button-add-issue"
  end

  def click_intake_finish
    safe_click "#button-finish-intake"
  end

  def click_intake_continue
    safe_click "#button-submit-review"
  end

  def click_edit_submit
    safe_click "#button-submit-update"
  end

  def click_intake_confirm
    safe_click ".confirm"
  end

  def click_edit_submit_and_confirm
    click_edit_submit
    click_intake_confirm
  end

  def click_intake_no_matching_issues
    safe_click ".no-matching-issues"
  end

  def add_intake_rating_issue(description, note = nil)
    # find_all with 'minimum' will wait like find() does.
    find_all("label", text: description, minimum: 1).first.click
    fill_in("Notes", with: note) if note
    safe_click ".add-issue"
  end

  def select_intake_no_match
    find_all("label", text: /^No VACOLS issues were found/, minimum: 1).first.click
    safe_click ".add-issue"
  end

  def get_claim_id(claim_review)
    EndProductEstablishment.find_by(source: claim_review).reference_id
  end

  def add_intake_nonrating_issue(
    benefit_type: "Compensation",
    category: "Active Duty Adjustments",
    description: "Some description",
    date: "01/01/2016",
    legacy_issues: false
  )
    add_button_text = legacy_issues ? "Next" : "Add this issue"
    expect(page.text).to match(/Does issue \d+ match any of these non-rating issue categories?/)
    expect(page).to have_button(add_button_text, disabled: true)

    # has_css will wait 5 seconds by default, and we want an instant decision.
    # we can trust the modal is rendered because of the expect() calls above.
    if page.has_css?("#issue-benefit-type", wait: 0)
      fill_in "Benefit type", with: benefit_type
      find("#issue-benefit-type").send_keys :enter
    end

    fill_in "Issue category", with: category
    find("#issue-category").send_keys :enter
    fill_in "Issue description", with: description
    fill_in "Decision date", with: date
    expect(page).to have_button(add_button_text, disabled: false)
    safe_click ".add-issue"
  end

  def add_active_intake_nonrating_issue(description)
    find_all("label", text: description, minimum: 1).first.click
    safe_click ".add-issue"
  end

  def add_intake_unidentified_issue(description = "unidentified issue description")
    safe_click ".no-matching-issues"
    safe_click ".no-matching-issues"
    expect(page).to have_content("Describe the issue to mark it as needing further review.")
    fill_in "Transcribe the issue as it's written on the form", with: description
    safe_click ".add-issue"
  end

  def click_remove_intake_issue(number)
    number = number.strip if number.is_a?(String)
    issue_el = find_intake_issue_by_number(number)
    issue_el.find(".remove-issue").click
  end

  def click_remove_intake_issue_dropdown(text)
    issue_el = find_intake_issue_by_text(text)
    issue_num = issue_el[:"data-key"].sub(/^issue-/, "")
    find("#issue-action-#{issue_num}").click
    find("#issue-action-#{issue_num}_remove").click
    click_remove_issue_confirmation
  end

  def click_withdraw_intake_issue_dropdown(text)
    issue_el = find_intake_issue_by_text(text)
    issue_num = issue_el[:"data-key"].sub(/^issue-/, "")
    find("#issue-action-#{issue_num}").click
    find("#issue-action-#{issue_num}_withdraw").click
  end

  def click_correct_intake_issue_dropdown(text)
    issue_el = find_intake_issue_by_text(text)
    issue_num = issue_el[:"data-key"].sub(/^issue-/, "")
    find("#issue-action-#{issue_num}").click
    find("#issue-action-#{issue_num}_correct").click
  end

  def select_correction_type_from_modal(value)
    find("label[for=correctionType_#{value}]").click
  end

  def click_correction_type_modal_submit
    find(".correction-type-submit").click
  end

  def click_remove_intake_issue_by_text(text)
    issue_el = find_intake_issue_by_text(text)
    issue_el.find(".remove-issue").click
  end

  def click_remove_issue_confirmation
    safe_click ".remove-issue"
  end

  def click_edit_contention_issue
    safe_click ".edit-contention-issue"
  end

  def edit_contention_text(old_text, new_text)
    issue_to_edit = find_all(:xpath, './/div[@class="issues"]/*/div[@class="issue-container"]')
      .select { |issue| issue.text.match?(/#{old_text}/) }.find(".issue-edit-text").first

    within issue_to_edit do
      click_edit_contention_issue
    end

    fill_in(with: new_text)
    click_button("Submit")
  end

  def click_number_of_issues_changed_confirmation
    safe_click "#Number-of-issues-has-changed-button-id-1"
  end

  def click_still_have_unidentified_issue_confirmation
    safe_click "#Unidentified-issue-button-id-1"
  end

  def find_intake_issue_by_number(number)
    find_all(:xpath, './/div[@class="issues"]/*/div[@class="issue-container"]').each do |node|
      if node.find(".issue-num").text.match?(/^#{number}\./)
        return node.find(".issue")
      end
    end
  end

  def find_intake_issue_by_text(text)
    find_all(:xpath, './/div[@class="issues"]/*/div[@class="issue-container"]').each do |node|
      if node.text.match?(/#{text}/)
        return node.find(".issue")
      end
    end
  end

  def find_intake_issue_number_by_text(text)
    find_intake_issue_by_text(text).find(".issue-num").text.delete(".")
  end

  # def find_correction_type_by_value(value)
  #   find_all(:xpath, './/div[@class="issues"]/*/div[@class="issue-container"]').each do |node|
  #     if node.text.match?(/#{text}/)
  #       return node.find(".issue")
  #     end
  #   end
  # end

  def expect_ineligible_issue(number)
    number = number.strip if number.is_a?(String)
    expect(find_intake_issue_by_number(number)).to have_css(".not-eligible")
  end

  def expect_eligible_issue(number)
    expect(find_intake_issue_by_number(number)).to_not have_css(".not-eligible")
  end

  def setup_active_eligible_legacy_appeal(veteran_file_number)
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :status_active,
        bfkey: "vacols1",
        bfcorlid: "#{veteran_file_number}S",
        bfdnod: 3.days.ago,
        bfdsoc: 3.days.ago,
        case_issues: [
          create(:case_issue, :ankylosis_of_hip),
          create(:case_issue, :limitation_of_thigh_motion_extension)
        ]
      ))
  end

  def setup_active_ineligible_legacy_appeal(veteran_file_number)
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :status_active,
        bfkey: "vacols2",
        bfcorlid: "#{veteran_file_number}S",
        bfdnod: 4.years.ago,
        bfdsoc: 4.months.ago,
        case_issues: [
          create(:case_issue, :intervertebral_disc_syndrome),
          create(:case_issue, :degenerative_arthritis_of_the_spine)
        ]
      ))
  end

  def setup_inactive_eligible_legacy_appeal(veteran_file_number)
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :status_complete,
        bfkey: "vacols3",
        bfcorlid: "#{veteran_file_number}S",
        bfdnod: 4.days.ago,
        bfdsoc: 4.days.ago,
        case_issues: [
          create(:case_issue, :impairment_of_hip),
          create(:case_issue, :impairment_of_femur, :disposition_opted_in)
        ]
      ))
  end

  def setup_inactive_ineligible_legacy_appeal(veteran_file_number)
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :status_complete,
        bfkey: "vacols4",
        bfcorlid: "#{veteran_file_number}S",
        bfdnod: 4.years.ago,
        bfdsoc: 4.months.ago,
        case_issues: [
          create(:case_issue, :typhoid_arthritis),
          create(:case_issue, :caisson_disease_of_bones)
        ]
      ))
  end

  def setup_active_ineligible_with_exemption(veteran_file_number)
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :status_active,
        bfkey: "vacols5",
        bfcorlid: "#{veteran_file_number}S",
        bfdnod: 3.years.ago,
        bfdsoc: Date.new(2019, 12, 28),
        case_issues: [
          create(:case_issue, :lumbosacral_strain),
          create(:case_issue, :shoulder_or_arm_muscle_injury)
        ]
      ))
  end

  def setup_active_eligible_with_exemption(veteran_file_number)
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :status_active,
        bfkey: "vacols6",
        bfcorlid: "#{veteran_file_number}S",
        bfdnod: 2.years.ago,
        bfdsoc: Date.new(2020, 2, 2),
        case_issues: [
          create(:case_issue, :rheumatoid_arthritis),
          create(:case_issue, :osteomyelitis)
        ]
      ))
  end

  def setup_legacy_opt_in_appeals(veteran_file_number)
    setup_active_eligible_legacy_appeal(veteran_file_number)
    setup_active_ineligible_legacy_appeal(veteran_file_number)
    setup_active_eligible_with_exemption(veteran_file_number)
    setup_active_ineligible_with_exemption(veteran_file_number)
    setup_inactive_eligible_legacy_appeal(veteran_file_number)
    setup_inactive_ineligible_legacy_appeal(veteran_file_number)
  end

  def setup_request_issue_with_nonrating_decision_issue(
    decision_review, nonrating_issue_category: "Active Duty Adjustments"
  )
    create(:request_issue,
           :with_nonrating_decision_issue,
           nonrating_issue_description: "Test nonrating decision issue",
           decision_review: decision_review,
           decision_date: decision_review.receipt_date - 1.day,
           nonrating_issue_category: nonrating_issue_category,
           veteran_participant_id: veteran.participant_id)
  end

  def setup_request_issue_with_rating_decision_issue(decision_review, contested_rating_issue_reference_id: "rating123")
    create(:request_issue,
           :with_rating_decision_issue,
           contested_rating_issue_reference_id: contested_rating_issue_reference_id,
           contested_rating_issue_profile_date: decision_review.receipt_date - 1.day,
           contested_issue_description: "Test rating decision issue",
           decision_review: decision_review,
           veteran_participant_id: veteran.participant_id)
  end

  def setup_prior_decision_issues(veteran, benefit_type: "compensation")
    supplemental_claim_with_decision_issues = create(:supplemental_claim,
                                                     veteran_file_number: veteran.file_number,
                                                     benefit_type: benefit_type)

    nonrating_request_issue = setup_request_issue_with_nonrating_decision_issue(supplemental_claim_with_decision_issues)
    rating_request_issue = setup_request_issue_with_rating_decision_issue(supplemental_claim_with_decision_issues)

    DecisionIssue.where(id: [nonrating_request_issue.contested_decision_issue_id,
                             rating_request_issue.contested_decision_issue_id])
  end

  def setup_prior_claim_with_payee_code(decision_review, veteran, prior_payee_code = "10")
    same_claimant = decision_review.claimant

    Generators::EndProduct.build(
      veteran_file_number: veteran.file_number,
      bgs_attrs: {
        benefit_claim_id: "claim_id",
        claimant_first_name: same_claimant.first_name,
        claimant_last_name: same_claimant.last_name,
        payee_type_code: prior_payee_code,
        claim_date: 5.days.ago
      }
    )
  end

  def setup_prior_decision_issue_chain(decision_review, request_issue, veteran, initial_date)
    create(:decision_issue,
           description: "alternate decision issue",
           participant_id: veteran.participant_id,
           disposition: "allowed",
           decision_review: decision_review,
           caseflow_decision_date: initial_date + 4.days,
           end_product_last_action_date: decision_review.is_a?(Appeal) ? nil : initial_date + 4.days,
           request_issues: [request_issue])

    decision_issue = create(:decision_issue,
                            description: "decision issue 0",
                            participant_id: veteran.participant_id,
                            disposition: "allowed",
                            decision_review: decision_review,
                            caseflow_decision_date: initial_date,
                            end_product_last_action_date: decision_review.is_a?(Appeal) ? nil : initial_date,
                            request_issues: [request_issue])

    contesting_decision_issue_id = decision_issue.id
    3.times do |index|
      later_appeal = create(:appeal, :outcoded, veteran: veteran)
      later_request_issue = create(:request_issue,
                                   decision_review: later_appeal,
                                   contested_decision_issue_id: contesting_decision_issue_id)
      later_decision_issue = create(:decision_issue,
                                    decision_review: later_appeal,
                                    disposition: "allowed",
                                    participant_id: veteran.participant_id,
                                    description: "decision issue #{1 + index}",
                                    caseflow_decision_date: initial_date + (1 + index).days,
                                    request_issues: [later_request_issue])
      contesting_decision_issue_id = later_decision_issue.id
    end
  end

  # rubocop:disable Metrics/AbcSize
  def check_decision_issue_chain(initial_date)
    visit "/intake/add_issues"

    click_intake_add_issue
    last_decision_date = (initial_date + 3.days).strftime("%m/%d/%Y")
    alternate_last_decision_date = (initial_date + 4.days).strftime("%m/%d/%Y")
    text = "(Please select the most recent decision on"
    datetext = "#{text} #{last_decision_date})"
    multiple_datetext = "#{text} #{last_decision_date}, #{alternate_last_decision_date})"

    expect(page).to have_content("Untimely rating issue 1 #{multiple_datetext}")
    expect(page).to have_content("decision issue 0 #{datetext}")
    expect(page).to have_content("decision issue 1 #{datetext}")
    expect(page).to have_content("decision issue 2 #{datetext}")
    expect(page).to have_content("alternate decision issue")
    expect(page).to have_content("decision issue 3")
  end
  # rubocop:enable Metrics/AbcSize

  def check_row(label, text)
    row = find("tr", text: label, match: :prefer_exact)
    expect(row).to have_text(text)
  end

  def mock_backfilled_rating_response
    allow_any_instance_of(Fakes::BGSService).to receive(:fetch_ratings_in_range)
      .and_return(rating_profile_list: { rating_profile: nil },
                  reject_reason: "Converted or Backfilled Rating - no promulgated ratings found")
  end

  def mock_locked_rating_response
    allow_any_instance_of(Fakes::BGSService).to receive(:fetch_ratings_in_range)
      .and_return(rating_profile_list: { rating_profile: nil },
                  reject_reason: "Locked Rating")
  end

  def generate_ratings_with_disabilities(veteran, promulgation_date, profile_date, issues: [])
    if issues == []
      issues = [
        {
          reference_id: "disability0",
          decision_text: "this is a disability"
        },
        {
          reference_id: "disability1",
          decision_text: "this is another disability"
        }
      ]
    end

    issues_with_disabilities = issues.map.with_index do |issue, i|
      issue[:rba_contentions_data] = [{ prfil_dt: promulgation_date, cntntn_id: nil }]
      issue[:dis_sn] = "rating#{i}"
      issue
    end

    disabilities = issues.map.with_index do |_issue, i|
      {
        dis_dt: promulgation_date.to_datetime,
        dis_sn: "rating#{i}",
        disability_evaluations: {
          dis_dt: promulgation_date.to_datetime,
          dgnstc_tc: "diagnostic_code#{i}"
        }
      }
    end

    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: promulgation_date,
      profile_date: profile_date,
      issues: issues_with_disabilities,
      disabilities: disabilities
    )
  end

  def generate_rating(veteran, promulgation_date, profile_date)
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: promulgation_date,
      profile_date: profile_date,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" },
        { reference_id: "def789", decision_text: "Looks like a VACOLS issue" }
      ]
    )
  end

  def generate_timely_rating(veteran, receipt_date, duplicate_reference_id)
    Generators::PromulgatedRating.build(
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

  def generate_untimely_rating(veteran, promulgation_date, profile_date)
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: promulgation_date,
      profile_date: profile_date,
      issues: [
        { reference_id: "old123", decision_text: "Untimely rating issue 1" },
        { reference_id: "old456", decision_text: "Untimely rating issue 2" }
      ]
    )
  end

  def generate_untimely_rating_from_ramp(veteran, receipt_date, old_reference_id, with_associated_claims: false)
    args = {
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - 400.days,
      profile_date: receipt_date - 450.days,
      issues: [
        { reference_id: old_reference_id,
          decision_text: "Really old injury" }
      ]
    }
    if with_associated_claims
      args[:associated_claims] = { bnft_clm_tc: "683SCRRRAMP", clm_id: "ramp_claim_id" }
    end
    Generators::PromulgatedRating.build(args)
  end

  def generate_future_rating(veteran, promulgation_date, profile_date)
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: promulgation_date,
      profile_date: profile_date,
      issues: [
        { reference_id: "future1", decision_text: "Future rating issue 1" },
        { reference_id: "future2", decision_text: "Future rating issue 2" }
      ]
    )
  end

  def generate_pre_ama_rating(veteran)
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: ama_test_start_date - 5.days,
      profile_date: ama_test_start_date - 10.days,
      issues: [
        { reference_id: "before_ama_ref_id", decision_text: "Non-RAMP Issue before AMA Activation" }
      ]
    )
  end

  def generate_rating_with_defined_contention(veteran, promulgation_date, profile_date)
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: promulgation_date,
      profile_date: profile_date,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted", contention_reference_id: 55 },
        { reference_id: "def456", decision_text: "PTSD denied" },
        { reference_id: "abcdef", decision_text: "Back pain" }
      ]
    )
  end

  def generate_rating_before_ama_from_ramp(veteran)
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: ama_test_start_date - 5.days,
      profile_date: ama_test_start_date - 11.days,
      issues: [
        { decision_text: "Issue before AMA Activation from RAMP",
          reference_id: "ramp_ref_id" }
      ],
      associated_claims: { bnft_clm_tc: "683SCRRRAMP", clm_id: "ramp_claim_id" }
    )
  end

  def generate_rating_with_legacy_issues(veteran, promulgation_date, profile_date)
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: promulgation_date,
      profile_date: profile_date,
      issues: [
        { reference_id: "has_legacy_issue", decision_text: "Issue with legacy issue not withdrawn" },
        { reference_id: "has_ineligible_legacy_appeal", decision_text: "Issue connected to ineligible legacy appeal" }
      ]
    )
  end

  def generate_rating_with_old_decisions(veteran, receipt_date)
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - 5.years,
      profile_date: receipt_date - 5.years,
      issues: [
        { reference_id: "9876", decision_text: "Left hand broken" }
      ],
      decisions: [
        {
          rating_issue_reference_id: nil,
          original_denial_date: receipt_date - 5.years - 3.days,
          diagnostic_text: "Right arm broken",
          diagnostic_type: "Bone",
          disability_id: "123",
          disability_date: receipt_date - 5.years - 2.days,
          type_name: "Not Service Connected"
        }
      ]
    )
  end

  def save_and_check_request_issues_with_diagnostic_codes(form_name, decision_review)
    click_intake_add_issue
    expect(page).to have_content("this is a disability")
    expect(page).to have_content("this is another disability")
    add_intake_rating_issue("this is another disability")

    if current_url.include?("/edit")
      click_edit_submit_and_confirm
      # edit page for appeals goes to queue
      expect(page).to have_content("View all cases")
    else
      click_intake_finish
      expect(page).to have_content("#{form_name} has been submitted.")
    end

    expect(
      RequestIssue.find_by(
        contested_rating_issue_diagnostic_code: "diagnostic_code1",
        contested_rating_issue_reference_id: "disability1",
        contested_issue_description: "this is another disability",
        decision_review: decision_review
      )
    ).to_not be_nil
  end

  # rubocop:disable Metrics/AbcSize
  def verify_decision_issues_can_be_added_and_removed(page_url,
                                                      original_request_issue,
                                                      decision_review,
                                                      contested_decision_issues)
    visit page_url
    expect(page).to have_content("currently contesting decision issue")
    expect(page).to have_content("PTSD denied")

    # check that we cannot add the same issue again
    click_intake_add_issue
    decision_date = contested_decision_issues.first.end_product_last_action_date.strftime("%m/%d/%Y")
    expect(page).to have_content("Past decisions from #{decision_date}")
    expect(page).to have_css("input[disabled]", visible: false)
    expect(page).to have_content("PTSD denied (already selected for")

    nonrating_decision_issue_description = "nonrating decision issue"
    rating_decision_issue_description = "a rating decision issue"
    # check that nonrating and rating decision issues show up

    expect(page).to have_content(nonrating_decision_issue_description)
    expect(page).to have_content(rating_decision_issue_description)
    safe_click ".close-modal"

    # remove original decision issue
    click_remove_intake_issue_dropdown("currently contesting decision issue")

    # add new decision issue
    click_intake_add_issue
    add_intake_rating_issue(rating_decision_issue_description)
    expect(page).to have_content(rating_decision_issue_description)

    click_intake_add_issue

    add_intake_rating_issue(nonrating_decision_issue_description)

    expect(page).to have_content(nonrating_decision_issue_description)

    # TODO: not clear if this test still applies. It is currently failing
    # but it is not clear if the conditions are still correct.
    # expect(page).to have_content(
    #  Constants.INELIGIBLE_REQUEST_ISSUES
    #     .duplicate_of_rating_issue_in_active_review.gsub("{review_title}", "Higher-Level Review")
    # )

    click_edit_submit_and_confirm
    expect(page).to have_current_path("/#{page_url}/confirmation")

    visit page_url
    expect(page).to have_content(nonrating_decision_issue_description)
    expect(page).to have_content(rating_decision_issue_description)
    expect(page).to have_content("PTSD denied")

    # check that decision_request_issue is closed
    updated_request_issue = RequestIssue.find_by(id: original_request_issue.id)
    expect(updated_request_issue.decision_review).to_not be_nil
    expect(updated_request_issue).to be_closed

    # check that new request issue is created contesting the decision issue
    request_issues = decision_review.reload.request_issues.active_or_ineligible
    first_request_issue = request_issues.find_by(contested_decision_issue_id: contested_decision_issues.first.id)
    second_request_issue = request_issues.find_by(contested_decision_issue_id: contested_decision_issues.second.id)

    expect(first_request_issue).to have_attributes(
      contested_issue_description: contested_decision_issues.first.description
    )

    expect(second_request_issue).to have_attributes(
      # TODO: same as above # ineligible_reason: "duplicate_of_rating_issue_in_active_review",
      contested_issue_description: contested_decision_issues.second.description
    )
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def verify_request_issue_contending_decision_issue_not_readded(
    page_url,
    decision_review,
    contested_decision_issues
  )
    # verify that not modifying a request issue contesting a decision issue
    # does not result in readding

    visit page_url
    expect(page).to have_content(contested_decision_issues.first.description)
    expect(page).to have_content(contested_decision_issues.second.description)
    expect(page).to have_content("PTSD denied")

    click_remove_intake_issue_dropdown("PTSD denied")

    click_intake_add_issue
    add_intake_rating_issue("Issue with legacy issue not withdrawn")

    click_edit_submit
    expect(page).to have_content("has been submitted")

    first_not_modified_request_issue = RequestIssue.find_by(
      decision_review: decision_review,
      contested_decision_issue_id: contested_decision_issues.first.id
    )

    second_not_modified_request_issue = RequestIssue.find_by(
      decision_review: decision_review,
      contested_decision_issue_id: contested_decision_issues.second.id
    )

    expect(first_not_modified_request_issue).to_not be_nil
    expect(second_not_modified_request_issue).to_not be_nil

    non_modified_ids = [first_not_modified_request_issue.id, second_not_modified_request_issue.id]
    request_issue_update = RequestIssuesUpdate.find_by(review: decision_review)

    # existing issues should not be added or removed
    expect(request_issue_update.added_issues.map(&:id)).to_not include(non_modified_ids)
    expect(request_issue_update.removed_issues.map(&:id)).to_not include(non_modified_ids)
  end
  # rubocop:enable Metrics/AbcSize

  def select_agree_to_withdraw_legacy_issues(withdraw)
    within_fieldset("Did the Veteran check the \"OPT-IN from SOC/SSOC\" box on the form?") do
      find("label", text: withdraw ? "Yes" : "N/A", match: :prefer_exact).click
    end
  end
end
# rubocop:enable Metrics/ModuleLength
