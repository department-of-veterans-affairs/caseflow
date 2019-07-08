# frozen_string_literal: true

require "support/intake_helpers"

feature "Intake Add Issues Page" do
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
      ]
    )
  end

  context "check for correct time zone" do
    scenario "when rating is added" do
      start_higher_level_review(veteran)
      visit "/intake"
      click_intake_continue
      expect(page).to have_current_path("/intake/add_issues")

      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")
      expect(page).not_to have_content("When you finish making changes, click \"Save\" to continue")
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
      find("label", text: "None of these match").click
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
end
