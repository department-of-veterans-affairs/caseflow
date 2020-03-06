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
    Generators::Rating.build(
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
        expect(page).to_not have_content("The Veteran's profile has missing or invalid information")
        expect(page).to have_button("Establish appeal", disabled: false)

        # Add a rating issue
        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")

        expect(page).to have_content("The Veteran's profile has missing or invalid information")
        expect(page).to have_content(
          "the corporate database, then retry establishing the EP in Caseflow: country."
        )
        expect(page).to have_content("This Veteran's address is too long. Please edit it in VBMS or SHARE")
        expect(page).to have_button("Establish appeal", disabled: true)

        click_remove_intake_issue_by_text("Left knee granted")
        expect(page).to_not have_content("The Veteran's profile has missing or invalid information")
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
        expect(page).to have_content("The Veteran's profile has missing or invalid information")
        expect(page).to have_button("Establish appeal", disabled: true)
      end
    end
  end

  context "when edit contention text feature is enabled" do
    before { FeatureToggle.enable!(:edit_contention_text) }

    it "Allows editing contention text on intake" do
      start_higher_level_review(veteran)
      visit "/intake"
      click_intake_continue
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")
      edit_contention_text("Left knee granted", "Right knee")
      expect(page).to_not have_content("Left knee granted")
      expect(page).to have_content("Right knee")
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
  end

  context "When the user adds an untimely issue" do
    before do
      Generators::Rating.build(
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
      expect(page).to have_content("Unidentified issue")

      unidentified_issue = RequestIssue.where(
        unidentified_issue_text: "Unidentified issue",
        untimely_exemption: false,
        ineligible_reason: "untimely"
      )

      expect(unidentified_issue).to_not be_nil
    end
  end
end
