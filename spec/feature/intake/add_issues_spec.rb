# frozen_string_literal: true

feature "Intake Add Issues Page", :all_dbs do
  include IntakeHelpers

  before do
    setup_intake_flags
  end

  let(:veteran_file_number) { "123412345" }
  let(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number, first_name: "Ed", last_name: "Merica")
  end
  let(:profile_date) { 10.days.ago }
  let(:promulgation_date) { 9.days.ago.to_date }
  let!(:rating) do
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: promulgation_date,
      profile_date: profile_date,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" },
        { reference_id: "def789", decision_text: "Looks like a VACOLS issue" }
      ],
      decisions: [
        {
          rating_issue_reference_id: nil,
          original_denial_date: promulgation_date - 7.days,
          diagnostic_text: "Broken arm",
          diagnostic_type: "Bone",
          disability_id: "123",
          disability_date: promulgation_date - 3.days,
          type_name: "Not Service Connected"
        }
      ]
    )
  end

  context "not service connected rating decision" do
    before { FeatureToggle.enable!(:contestable_rating_decisions) }
    after { FeatureToggle.disable!(:contestable_rating_decisions) }

    let(:rating_decision_text) { "Bone (Broken arm) is denied." }

    scenario "rating decision is selected" do
      start_higher_level_review(veteran)
      visit "/intake"
      click_intake_continue
      expect(page).to have_current_path("/intake/add_issues")

      click_intake_add_issue
      add_intake_rating_issue(rating_decision_text)
      expect(page).to have_content("1. #{rating_decision_text}\nDecision date: #{promulgation_date.mdY}")
    end
  end

  context "check for correct time zone" do
    scenario "when rating is added" do
      start_higher_level_review(veteran)
      visit "/intake"
      click_intake_continue
      expect(page).to have_current_path("/intake/add_issues")

      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")
      expect(page.has_no_content?("When you finish making changes, click \"Save\" to continue")).to eq(true)
      expect(page).to have_content("1. Left knee granted\nDecision date: #{promulgation_date.mdY}")
    end
  end

  context "for an Appeal" do
    context "when there is an invalid veteran" do
      let!(:veteran) do
        Generators::Veteran.build(
          file_number: "25252525",
          sex: nil,
          ssn: nil,
          country: nil,
          address_line1: "this address is more than 20 chars"
        )
      end

      scenario "check invalid veteran alert if any added issues are a VBMS benefit type" do
        start_appeal(veteran)
        visit "/intake"
        click_intake_continue
        expect(page).to have_current_path("/intake/add_issues")

        # Add issue that is not a VBMS issue
        click_intake_add_issue
        click_intake_no_matching_issues
        add_intake_nonrating_issue(
          benefit_type: "Education",
          category: "Accrued",
          description: "Description for Accrued",
          date: 1.day.ago.to_date.mdY
        )

        expect(page).to have_content("Description for Accrued")
        expect(page).to_not have_content("Check the Veteran's profile for invalid information")
        expect(page).to have_button("Establish appeal", disabled: false)

        # Add a rating issue
        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")

        expect(page).to have_content("Check the Veteran's profile for invalid information")
        expect(page).to have_content(
          "the corporate database, then retry establishing the EP in Caseflow: country."
        )
        expect(page).to have_content("This Veteran's address is too long. Please edit it in VBMS or SHARE")
        expect(page).to have_button("Establish appeal", disabled: true)

        click_remove_intake_issue_by_text("Left knee granted")
        expect(page).to_not have_content("Check the Veteran's profile for invalid information")
        expect(page).to have_button("Establish appeal", disabled: false)

        # Add a compensation nonrating issue
        click_intake_add_issue
        click_intake_no_matching_issues
        add_intake_nonrating_issue(
          benefit_type: "Compensation",
          category: "Apportionment",
          description: "Description for Apportionment",
          date: 2.days.ago.to_date.mdY
        )

        expect(page).to have_content("Description for Apportionment")
        expect(page).to have_content("Check the Veteran's profile for invalid information")
        expect(page).to have_button("Establish appeal", disabled: true)
      end
    end
  end

  context "when edit contention text feature is enabled" do
    it "Allows editing contention text on intake" do
      start_higher_level_review(veteran)
      visit "/intake"
      click_intake_continue
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")
      edit_contention_text("Left knee granted", "Right knee")
      expect(page).to have_content("Right knee")
      expect(page).to have_content("(Originally: Left knee granted)")
      click_intake_finish

      expect(page).to have_content("Request for #{Constants.INTAKE_FORM_NAMES.higher_level_review} has been submitted.")
      expect(page).to have_content("Right knee")
      expect(RequestIssue.where(edited_description: "Right knee")).to_not be_nil
    end
  end

  context "check that none of these match works for VACOLS issue" do
    before do
      setup_legacy_opt_in_appeals(veteran.file_number)
    end

    scenario "User selects a vacols issue, then changes to none of these match" do
      start_appeal(veteran, legacy_opt_in_approved: true)
      visit "/intake/add_issues"
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")

      expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
      find("label", text: "intervertebral disc syndrome").click
      find("label", text: /^No VACOLS issues were found/).click
      safe_click ".add-issue"

      expect(page).to have_content("Left knee granted\nDecision date")
      expect(page).to_not have_content(
        "Left knee granted is ineligible because the same issue is under review as a Legacy Appeal"
      )
    end

    scenario "User selects a vacols issue, issue description shows on legacy modal" do
      start_higher_level_review(veteran, legacy_opt_in_approved: true)
      visit "/intake/add_issues"
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Apportionment",
        description: "Description for Apportionment",
        date: 1.day.ago.to_date.mdY,
        legacy_issues: true
      )

      expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
      expect(page).to have_content("Description for Apportionment")
    end
  end

  context "When the user adds an untimely issue" do
    before do
      Generators::PromulgatedRating.build(
        participant_id: veteran.participant_id,
        promulgation_date: 2.years.ago,
        profile_date: 2.years.ago,
        issues: [
          { reference_id: "untimely", decision_text: "Untimely Issue" }
        ]
      )
    end

    scenario "When the user selects untimely exemption it shows untimely exemption notes" do
      start_appeal(veteran, legacy_opt_in_approved: true)
      visit "/intake/add_issues"
      click_intake_add_issue
      add_intake_rating_issue("Untimely Issue")
      expect(page).to_not have_content("Notes")
      expect(page).to have_content("Issue 1 is an Untimely Issue")
      find("label", text: "Yes").click
      expect(page).to have_content("Notes")
    end

    context "with covid_timeliness_exemption feature toggle" do
      before { FeatureToggle.enable!(:covid_timeliness_exemption) }
      after { FeatureToggle.disable!(:covid_timeliness_exemption) }

      context "for higher level review" do
        scenario "When the user selects untimely exemption it shows COVID-19 exemption notice" do
          start_higher_level_review(veteran)
          visit "/intake"
          click_intake_continue
          expect(page).to have_current_path("/intake/add_issues")

          click_intake_add_issue
          add_intake_rating_issue("Untimely Issue")
          expect(page).to_not have_content("Notes")
          expect(page).to have_content("Issue 1 is an Untimely Issue")
          find("label", text: "Yes").click
          expect(page).to have_content("This request is related to COVID-19")
          find('label[for="untimelyExemptionCovid"]').click
          safe_click ".add-issue"
          expect(page).to have_content("Untimely Issue")
          click_on "Establish EP"
          expect(page).to have_content("Intake completed")

          expect(RequestIssue.all.size).to eq(1)
          untimely_issue = RequestIssue.first
          expect(untimely_issue.covid_timeliness_exempt).to eq(true)
        end
      end
    end
  end

  context "show decision date on unidentified issues" do
    let(:veteran_no_ratings) do
      Generators::Veteran.build(file_number: "55555555",
                                first_name: "Nora",
                                last_name: "Attings",
                                participant_id: "44444444")
    end
    let(:decision_date) { 50.days.ago.to_date.mdY }
    let(:untimely_days) { 2.years.ago.to_date.mdY }

    before { FeatureToggle.enable!(:unidentified_issue_decision_date) }
    after { FeatureToggle.disable!(:unidentified_issue_decision_date) }

    scenario "unidentified issue decision date on add issue page" do
      start_higher_level_review(veteran_no_ratings)
      visit "/intake"
      click_intake_continue
      expect(page).to have_current_path("/intake/add_issues")

      click_intake_add_issue
      click_intake_no_matching_issues
      expect(page).to have_content("Decision date")
      fill_in "Transcribe the issue as it's written on the form", with: "unidentified issue"
      fill_in "Decision date", with: decision_date
      safe_click ".add-issue"
      expect(page).to have_content("Decision date")
      click_on "Establish EP"
      expect(page).to have_content("Intake completed")
    end

    scenario "show undentified decision date on edit page" do
      start_higher_level_review(veteran_no_ratings)
      visit "/intake"
      click_intake_continue
      expect(page).to have_current_path("/intake/add_issues")

      click_intake_add_issue
      click_intake_no_matching_issues
      expect(page).to have_content("Decision date")
      fill_in "Transcribe the issue as it's written on the form", with: "unidentified issue"
      fill_in "Decision date", with: decision_date
      safe_click ".add-issue"
      expect(page).to have_content("Decision date")
      click_on "Establish EP"
      click_on "correct the issues"
      expect(page).to have_content("Decision date")
    end

    scenario "show correct the issues link on appeal" do
      start_appeal(veteran_no_ratings)
      visit "/intake"
      click_intake_continue
      expect(page).to have_current_path("/intake/add_issues")

      click_intake_add_issue
      add_intake_nonrating_issue(
        category: "Dependent Child - Biological",
        description: "test",
        date: 30.days.ago.to_date.strftime("%m/%d/%Y")
      )
      click_on "Establish appeal"
      expect(page).to have_content("correct the issues")
      click_on "correct the issues"
      appeal = Appeal.find_by(docket_type: "evidence_submission")
      correct_path = "/appeals/#{appeal.uuid}/edit"
      expect(page).to have_current_path(correct_path)
    end

    scenario "show unidentified untimely exemption issue" do
      start_higher_level_review(veteran_no_ratings)
      visit "/intake"
      click_intake_continue
      expect(page).to have_current_path("/intake/add_issues")

      click_intake_add_issue
      click_intake_no_matching_issues
      expect(page).to have_content("Decision date")
      fill_in "Transcribe the issue as it's written on the form", with: "Unidentified issue"
      fill_in "Decision date", with: untimely_days
      fill_in "Notes", with: "PTSD issue"
      safe_click ".add-issue"

      # show untimely modal
      expect(page).to have_content("Issue 1 is an Untimely Issue")
      add_untimely_exemption_response("Yes")
      expect(page).to have_content("I am an exemption note")
      click_on "Establish EP"
      expect(page).to have_content("Unidentified issue")

      untimely_issue = RequestIssue.where(
        unidentified_issue_text: "Unidentified issue",
        untimely_exemption: true,
        untimely_exemption_notes: "I am an exemption note"
      )
      expect(untimely_issue).to_not be_nil
    end

    scenario "show unidentified issue when user selects no on untimely exemption modal " do
      start_higher_level_review(veteran_no_ratings)
      visit "/intake"
      click_intake_continue
      expect(page).to have_current_path("/intake/add_issues")

      click_intake_add_issue
      click_intake_no_matching_issues
      expect(page).to have_content("Decision date")
      fill_in "Transcribe the issue as it's written on the form", with: "Unidentified issue"
      fill_in "Decision date", with: untimely_days
      fill_in "Notes", with: "PTSD issue"
      safe_click ".add-issue"

      # show untimely modal
      expect(page).to have_content("Issue 1 is an Untimely Issue")
      add_untimely_exemption_response("No")
      expect(page).to have_content("Unidentified issue")
      click_on "Establish EP"

      expect(page).to have_content(RequestIssue::UNIDENTIFIED_ISSUE_MSG)

      unidentified_issue = RequestIssue.where(
        unidentified_issue_text: "Unidentified issue",
        untimely_exemption: false,
        ineligible_reason: "untimely"
      )

      expect(unidentified_issue).to_not be_nil
    end
  end

  context "show untimely issue modal with covid_timeliness_exemption feature toggle" do
    before do
      FeatureToggle.enable!(:covid_timeliness_exemption)
      setup_legacy_opt_in_appeals(veteran.file_number)
    end
    after { FeatureToggle.disable!(:covid_timeliness_exemption) }
    let!(:rating_before_ama) { generate_pre_ama_rating(veteran) }
    # let!(:ratings_with_legacy_issues) do
    #   generate_rating_with_legacy_issues(veteran, receipt_date - 4.days, receipt_date - 4.days)
    # end

    let(:receipt_date) { Time.zone.today - 30.days }
    let(:promulgation_date) { receipt_date - 10.days }
    let(:benefit_type) { "compensation" }
    let(:untimely_days) { 372.days }
    let(:profile_date) { (receipt_date - 8.days).to_datetime }
    let(:untimely_promulgation_date) { receipt_date - untimely_days - 1.day }
    let(:untimely_profile_date) { receipt_date - untimely_days - 3.days }

    let!(:rating) { generate_rating(veteran, promulgation_date, profile_date) }
    let!(:untimely_ratings) { generate_untimely_rating(veteran, untimely_promulgation_date, untimely_profile_date) }

    let!(:old_ratings) do
      Generators::PromulgatedRating.build(
        participant_id: veteran.participant_id,
        promulgation_date: receipt_date - 372.days,
        profile_date: receipt_date - 372.days,
        issues: [
          { reference_id: "abc127", decision_text: "Left knee issue granted" },
          { reference_id: "def457", decision_text: "PTSD1 denied" }
        ]
      )
    end

    context "on a higher level review" do
      scenario "when vacols issue is ineligible, but is eligible with an exemption" do
        start_higher_level_review(veteran, legacy_opt_in_approved: true)
        visit "/intake/add_issues"
        click_intake_add_issue
        add_intake_rating_issue("PTSD denied")

        # Expect legacy opt in issue modal to show
        expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
        add_intake_rating_issue("osteomyelitis")

        # Expect untimely issue modal to show
        expect(page).to have_content("Issue 1 is an Untimely Issue")
        expect(page).to have_content(
          "The legacy issue isn't eligible for SOC/SSOC opt-in unless an exemption has been requested"
        )
        find("label", text: "No").click
        safe_click ".add-issue"

        expect(page).to have_content("PTSD denied is ineligible")

        click_remove_intake_issue_by_text("PTSD denied")
        click_intake_add_issue
        add_intake_rating_issue("PTSD denied")
        add_intake_rating_issue("osteomyelitis")
        find("label", text: "Yes").click
        find('label[for="untimelyExemptionCovid"]').click
        safe_click ".add-issue"

        expect(page).to have_content("Adding this issue will automatically close VACOLS issue")

        click_on "Establish EP"
        expect(page).to have_content("Intake completed")
      end

      scenario "when vacols issue ineligible even with an exemption" do
        start_higher_level_review(veteran, legacy_opt_in_approved: true)
        visit "/intake/add_issues"
        click_intake_add_issue
        add_intake_rating_issue("PTSD denied")

        # Expect legacy opt in issue modal to show
        expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
        add_intake_rating_issue("lumbosacral strain")

        # Expect untimely issue modal not to show
        expect(page).to_not have_content("Issue 1 is an Untimely Issue")
      end

      scenario "when request issue is ineligible" do
        start_higher_level_review(veteran, legacy_opt_in_approved: true)
        visit "/intake/add_issues"
        click_intake_add_issue
        add_intake_rating_issue("Left knee issue granted")

        # Expect legacy opt in issue modal to show
        expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
        add_intake_rating_issue("ankylosis of hip")

        # Expect untimely issue modal to show
        expect(page).to have_content("Issue 1 is an Untimely Issue")
        expect(page).to have_content(
          "The issue requested isn't usually eligible because its decision date is older than what's allowed"
        )
      end

      scenario "when request and vacols issue are both ineligible" do
        start_higher_level_review(veteran, legacy_opt_in_approved: true)
        visit "/intake/add_issues"
        click_intake_add_issue
        add_intake_rating_issue("Left knee issue granted")

        # Expect legacy opt in issue modal to show
        expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
        add_intake_rating_issue("osteomyelitis")

        # Expect untimely issue modal to show
        expect(page).to have_content("Issue 1 is an Untimely Issue")
        expect(page).to have_content(
          "its decision date is older than what is allowed, and the legacy issue issue isn't eligible for SOC/SSOC "
        )
      end

      scenario "when request and vacols issue are both eligible" do
        start_higher_level_review(veteran, legacy_opt_in_approved: true)
        visit "/intake/add_issues"
        click_intake_add_issue
        add_intake_rating_issue("PTSD denied")

        # Expect legacy opt in issue modal to show
        expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
        add_intake_rating_issue("ankylosis of hip")

        # Expect untimely issue modal not to show
        expect(page).to_not have_content("Issue 1 is an Untimely Issue")
      end
    end

    context "on a supplemental claim" do
      scenario "when vacols issue is ineligible, but eligible with an exemption" do
        start_supplemental_claim(veteran, legacy_opt_in_approved: true)
        visit "/intake/add_issues"
        click_intake_add_issue
        add_intake_rating_issue("PTSD denied")

        # Expect legacy opt in issue modal to show
        expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
        add_intake_rating_issue("osteomyelitis")

        # Expect untimely issue modal to show
        expect(page).to have_content("Issue 1 is an Untimely Issue")
        expect(page).to have_content(
          "The legacy issue isn't eligible for SOC/SSOC opt-in unless an exemption has been requested"
        )
        find("label", text: "No").click
        safe_click ".add-issue"

        expect(page).to have_content("PTSD denied is ineligible")

        click_remove_intake_issue_by_text("PTSD denied")
        click_intake_add_issue
        add_intake_rating_issue("PTSD denied")
        add_intake_rating_issue("osteomyelitis")
        find("label", text: "Yes").click
        find('label[for="untimelyExemptionCovid"]').click
        safe_click ".add-issue"

        expect(page).to have_content("Adding this issue will automatically close VACOLS issue")

        click_on "Establish EP"
        expect(page).to have_content("Intake completed")
      end

      scenario "when vacols issue is ineligible even with an exemption" do
        start_supplemental_claim(veteran, legacy_opt_in_approved: true)
        visit "/intake/add_issues"
        click_intake_add_issue
        add_intake_rating_issue("PTSD denied")

        # Expect legacy opt in issue modal to show
        expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
        add_intake_rating_issue("lumbosacral strain")

        # Expect untimely issue modal to not show
        expect(page).to_not have_content("Issue 1 is an Untimely Issue")
      end

      scenario "when vacols issue is eligible on a supplemental claim" do
        start_supplemental_claim(veteran, legacy_opt_in_approved: true)
        visit "/intake/add_issues"
        click_intake_add_issue
        add_intake_rating_issue("PTSD denied")

        # Expect legacy opt in issue modal to show
        expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
        add_intake_rating_issue("ankylosis of hip")

        # Expect untimely issue modal to show
        expect(page).to_not have_content("Issue 1 is an Untimely Issue")
      end
    end

    context "on an appeal" do
      scenario "when request issue is ineligible and no vacols id on appeal" do
        start_appeal(veteran, legacy_opt_in_approved: true)
        visit "/intake/add_issues"
        click_intake_add_issue
        add_intake_rating_issue("Left knee issue granted")

        # Expect legacy opt in issue modal to show
        expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
        find("label", text: /^No VACOLS issues were found/).click
        safe_click ".add-issue"

        # Expect untimely issue modal to show
        expect(page).to have_content("Issue 1 is an Untimely Issue")
        expect(page).to have_content(
          "The issue requested isn't usually eligible because its decision date is older than what's allowed"
        )
      end

      scenario "when request issue is eligible and vacols issue added on appeal" do
        start_appeal(veteran, legacy_opt_in_approved: true)
        visit "/intake/add_issues"
        click_intake_add_issue
        add_intake_rating_issue("PTSD denied")

        # Expect legacy opt in issue modal to show
        expect(page).to have_content("Does issue 1 match any of these VACOLS issues?")
        add_intake_rating_issue("lumbosacral strain")

        # Expect untimely issue modal to show
        expect(page).to_not have_content("Issue 1 is an Untimely Issue")
      end
    end

    context "when attorney_fees featureToggle is permanently disabled" do
      scenario "checks that attorney categories do not exist on compensation" do
        start_higher_level_review(veteran_no_ratings)
        visit "/intake"
        click_intake_continue
        expect(page).to have_current_path("/intake/add_issues")

        click_intake_add_issue
        expect(page).to have_content("Does issue 1 match any of these non-rating issue categories?")
        find(".cf-select__control").click
        expect(page).to_not have_content("Contested Claims - Attorney fees")
        expect(page).to have_content("Active Duty Adjustments")
      end
    end

  end
end
