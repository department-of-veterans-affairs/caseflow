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
  let(:veteran_no_ratings) do
    Generators::Veteran.build(file_number: "55555555",
                              first_name: "Nora",
                              last_name: "Attings",
                              participant_id: "44444444")
  end
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
          category: "Contested Claims - Apportionment",
          description: "Description for Apportionment",
          date: 2.days.ago.to_date.mdY
        )

        expect(page).to have_content("Description for Apportionment")
        expect(page).to have_content("Check the Veteran's profile for invalid information")
        expect(page).to have_button("Establish appeal", disabled: true)
      end

      context "when appeal Type is Veterans Health Administration By default (Predocket option)" do
        scenario "appeal with benefit type VHA" do
          start_appeal(veteran)
          visit "/intake"
          click_intake_continue
          expect(page).to have_current_path("/intake/add_issues")
          click_intake_add_issue
          click_intake_no_matching_issues
          fill_in "Benefit type", with: "Veterans Health Administration"
          find("#issue-benefit-type").send_keys :enter
          fill_in "Issue category", with: "Beneficiary Travel"
          find("#issue-category").send_keys :enter
          fill_in "Issue description", with: "I am a VHA issue"
          fill_in "Decision date", with: 1.month.ago.mdY
          radio_choices = page.all(".cf-form-radio-option > label")
          expect(radio_choices[0]).to have_content("Yes")
          expect(radio_choices[1]).to have_content("No")
          expect(find("#is-predocket-needed_true", visible: false).checked?).to eq(true)
          expect(find("#is-predocket-needed_false", visible: false).checked?).to eq(false)
          expect(page).to have_content(COPY::VHA_PRE_DOCKET_ISSUE_BANNER)
        end
      end

      context "when adding a contested claim to an appeal" do
        def add_contested_claim_issue
          click_intake_add_issue
          click_intake_no_matching_issues

          # add the cc issue
          dropdown_select_string = "Select or enter..."
          benefit_text = "Insurance"

          # Select the benefit type
          all(".cf-select__control", text: dropdown_select_string).first.click
          find("div", class: "cf-select__option", text: benefit_text).click

          # Select the issue category
          find(".cf-select__control", text: dropdown_select_string).click
          find("div", class: "cf-select__option", text: "Contested Death Claim | Intent of Insured").click

          # fill in date and issue description
          fill_in "Decision date", with: 1.day.ago.to_date.mdY.to_s
          fill_in "Issue description", with: "CC Instructions"

          # click buttons
          click_on "Add this issue"
          click_on "Establish appeal"
        end

        before do
          ClerkOfTheBoard.singleton
          FeatureToggle.enable!(:cc_appeal_workflow)
          FeatureToggle.enable!(:indicator_for_contested_claims)
        end
        after do
          FeatureToggle.disable!(:cc_appeal_workflow)
          FeatureToggle.disable!(:indicator_for_contested_claims)
        end

        scenario "the appeal is evidence submission" do
          start_appeal(veteran)
          visit "/intake"
          click_intake_continue
          expect(page).to have_current_path("/intake/add_issues")

          # method to process add issues page with cc issue
          add_contested_claim_issue

          appeal = Appeal.find_by(veteran_file_number: veteran.file_number)
          appeal.reload

          # expect the SendInitialNotificationLetterHoldingTask to be created and assigned to COB
          expect(page).to have_content("Intake completed")
          expect(appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").nil?).to be false
          expect(
            appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").parent
          ).to eql(appeal.tasks.find_by(type: "EvidenceSubmissionWindowTask"))
          expect(
            appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").assigned_to
          ).to eql(ClerkOfTheBoard.singleton)
        end

        scenario "the appeal is direct review" do
          start_appeal(veteran)
          visit "/intake"
          find("label", text: "Direct Review").click
          click_intake_continue
          expect(page).to have_current_path("/intake/add_issues")

          # method to process add issues page with cc issue
          add_contested_claim_issue

          appeal = Appeal.find_by(veteran_file_number: veteran.file_number)
          appeal.reload

          # expect the SendInitialNotificationLetterHoldingTask to be created and assigned to COB
          expect(page).to have_content("Intake completed")
          expect(appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").nil?).to be false
          expect(
            appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").parent
          ).to eql(appeal.tasks.find_by(type: "DistributionTask"))
          expect(
            appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").assigned_to
          ).to eql(ClerkOfTheBoard.singleton)
        end

        scenario "the appeal is a hearing request" do
          start_appeal(veteran)
          visit "/intake"
          find("label", text: "Hearing").click
          click_intake_continue
          expect(page).to have_current_path("/intake/add_issues")

          # method to process add issues page with cc issue
          add_contested_claim_issue

          appeal = Appeal.find_by(veteran_file_number: veteran.file_number)
          appeal.reload

          # expect the SendInitialNotificationLetterHoldingTask to be created and assigned to COB
          expect(page).to have_content("Intake completed")
          expect(appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").nil?).to be false
          expect(
            appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").parent
          ).to eql(appeal.tasks.find_by(type: "ScheduleHearingTask"))
          expect(
            appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").assigned_to
          ).to eql(ClerkOfTheBoard.singleton)
        end
      end

      context "when the veteran does not have a POA"
      before { FeatureToggle.enable!(:hlr_sc_unrecognized_claimants) }
      after { FeatureToggle.disable!(:hlr_sc_unrecognized_claimants) }

      let(:no_poa_veteran) { create(:veteran, participant_id: "NO_POA111111113", file_number: "111111113") }

      scenario "the correct text displays for VHA" do
        start_claim_review(:higher_level_review, benefit_type: "vha", veteran: no_poa_veteran)
        visit "/intake"
        click_intake_continue
        expect(page).to have_current_path("/intake/add_issues")
        expect(page).to have_content(COPY::VHA_NO_POA)
      end

      scenario "the correct text displays for non-VHA" do
        start_claim_review(:higher_level_review, veteran: no_poa_veteran)
        visit "/intake"
        click_intake_continue
        expect(page).to have_current_path("/intake/add_issues")
        expect(page).to have_content(COPY::ADD_CLAIMANT_CONFIRM_MODAL_NO_POA)
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
  end

  context "show decision date on unidentified issues" do
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

      unidentified_issue = RequestIssue.where(
        unidentified_issue_text: "Unidentified issue",
        untimely_exemption: false,
        ineligible_reason: "untimely"
      )

      expect(unidentified_issue).to_not be_nil
    end
  end

  context "on an appeal" do
    scenario "check that hearing type field is present because docket type is hearing and hearing type is not nil" do
      start_appeal(veteran, docket_type: Constants.AMA_DOCKETS.hearing, original_hearing_request_type: "video")
      visit "/intake"
      click_intake_continue
      expect(page).to have_current_path("/intake/add_issues")

      expect(page).to have_content("Hearing type")
    end

    scenario "check that hearing type field is missing because docket type is not hearing" do
      # docket_type defaults to 'evidence_submission'
      start_appeal(veteran)
      visit "/intake"
      click_intake_continue
      expect(page).to have_current_path("/intake/add_issues")

      expect(page).to_not have_content("Hearing type")
    end

    scenario "check that hearing type field is missing because hearing type is nil" do
      start_appeal(veteran, docket_type: Constants.AMA_DOCKETS.hearing)
      visit "/intake"
      click_intake_continue
      expect(page).to have_current_path("/intake/add_issues")

      expect(page).to_not have_content("Hearing type")
    end
  end
end
