# frozen_string_literal: true

feature "Vha Higher-Level Review and Supplemental Claims Enter No Decision Date", :all_dbs do
  include IntakeHelpers

  let!(:current_user) do
    create(:user, roles: ["Mail Intake"])
  end

  let(:veteran_file_number) { "123412345" }

  let(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number,
                              first_name: "Ed",
                              last_name: "Merica")
  end

  let(:changed_issue_banner_save_text) do
    "When you finish making changes, click \"Save\" to continue."
  end

  let(:changed_issue_banner_establish_text) do
    "When you finish making changes, click \"Establish\" to continue."
  end

  before do
    VhaBusinessLine.singleton.add_user(current_user)
    CaseReview.singleton.add_user(current_user)
    current_user.save
    User.authenticate!(user: current_user)
  end

  shared_examples "Vha HLR/SC Issue without decision date" do
    it "Allows Vha to intake, edit, and establish a claim review with an issue without a decision date" do
      intake_type

      visit "/intake"

      click_intake_continue
      click_intake_add_issue
      add_intake_nonrating_issue(
        category: "Beneficiary Travel",
        description: "Travel for VA meeting",
        date: nil
      )

      expect(page).to have_content("1 issue")
      expect(page).to have_content("Decision date: No date entered")
      expect(page).to have_content(COPY::VHA_NO_DECISION_DATE_BANNER)
      expect(page).to have_content(intake_button_text)

      click_intake_finish

      # On hold tasks should land on the incomplete tab
      expect(page).to have_content(COPY::VHA_INCOMPLETE_TAB_DESCRIPTION)
      expect(page).to have_content(success_message_text)

      # Verify that the task has a status of on_hold
      task = DecisionReviewTask.last
      expect(task.status).to eq("on_hold")

      # Click the link and check to make sure that we are now on the edit issues page
      click_link veteran.name.to_s

      expect(page).to have_content("Edit Issues")
      expect(page).to have_content("Decision date: No date entered")
      expect(page).to have_content(COPY::VHA_NO_DECISION_DATE_BANNER)

      expect(page).to have_button("Save", disabled: true)

      issue_id = RequestIssue.last.id

      # Click the first issue actions button and select Add a decision date
      within "#issue-#{issue_id}" do
        first("select").select("Add decision date")
      end

      # Check modal text
      expect(page).to have_content("Add Decision Date")
      expect(page).to have_content("Issue:Beneficiary Travel")
      expect(page).to have_content("Benefit type:Veterans Health Administration")
      expect(page).to have_content("Issue description:Travel for VA meeting")

      future_date = (Time.zone.now + 1.week).strftime("%m/%d/%Y")
      past_date = (Time.zone.now - 1.week).strftime("%m/%d/%Y")
      another_past_date = (Time.zone.now - 2.weeks).strftime("%m/%d/%Y")

      fill_in "decision-date", with: future_date

      expect(page).to have_content("Dates cannot be in the future")

      # The button should be disabled since the date is in the future
      within ".cf-modal-controls" do
        expect(page).to have_button("Save", disabled: true)
      end

      # Test the modal cancel button
      within ".cf-modal-controls" do
        click_on "Cancel"
      end

      expect(page).to_not have_content("Add Decision Date")

      # Open the modal again
      # Click the first issue actions button and select Add a decision date
      within "#issue-#{issue_id}" do
        first("select").select("Add decision date")
      end

      expect(page).to have_content("Add Decision Date")

      fill_in "decision-date", with: past_date

      within ".cf-modal-controls" do
        expect(page).to have_button("Save", disabled: false)
        click_on("Save")
      end

      # Test functionality for editing a decision date once one has been selected
      # Click the first issue actions button and select Edit decision date
      within "#issue-#{issue_id}" do
        select("Edit decision date", from: "issue-action-0")
      end

      formatted_past_date = (Time.zone.now - 1.week).strftime("%Y-%m-%d")
      within ".cf-modal-body" do
        expect(page).to have_content("Edit Decision Date")
        expect(page).to have_field(type: "date", with: formatted_past_date)
      end

      fill_in "decision-date", with: another_past_date

      within ".cf-modal-controls" do
        expect(page).to have_button("Save", disabled: false)
        click_on("Save")
      end

      expect(page).to have_content(changed_issue_banner_establish_text)

      # Check that the Edit Issues save button is now Establish, the decision date is added, and the banner is gone
      expect(page).to_not have_content(COPY::VHA_NO_DECISION_DATE_BANNER)
      expect(page).to have_content("Decision date: #{another_past_date}")
      expect(page).to have_button("Establish", disabled: false)

      click_on("Establish")

      # the task should now be assigned and on the in progress tab
      expect(page).to_not have_content(COPY::VHA_INCOMPLETE_TAB_DESCRIPTION)
      expect(page).to have_content(edit_establish_success_message_text)
      expect(current_url).to include("/decision_reviews/vha?tab=in_progress")

      expect(task.reload.status).to eq("assigned")

      # Test adding a new issue without decision date then adding one
      # Click the links and get to the edit issues page
      click_link veteran.name.to_s
      click_link "Edit Issues"
      expect(page).to have_content("Edit Issues")

      # Open Add Issues modal and add issue
      click_on("Add issue")

      fill_in "Issue category", with: "Beneficiary Travel"
      find("#issue-category").send_keys :enter
      fill_in "Issue description", with: "Test description"

      expect(page).to have_button("Add this issue", disabled: false)
      click_on("Add this issue")

      # Test that the banner and text is present for added issues with no decision dates
      expect(page).to have_content("Decision date: No date entered")
      expect(page).to have_content(COPY::VHA_NO_DECISION_DATE_BANNER)

      # Edit the decision date for added issue
      # this is issue-undefined because the issue has not yet been created and does not have an id
      within "#issue-undefined" do
        select("Add decision date", from: "issue-action-1")
      end

      fill_in "decision-date", with: past_date

      within ".cf-modal-controls" do
        expect(page).to have_button("Save", disabled: false)
        click_on("Save")
      end

      # Check that the date gets saved and shows establish for added issue
      expect(page).to_not have_content(COPY::VHA_NO_DECISION_DATE_BANNER)
      expect(page).to have_content("Decision date: #{past_date}")
      expect(page).to have_button("Establish", disabled: false)

      click_on("Establish")
      expect(page).to have_content("Number of issues has changed")
      click_on("Yes, save")

      expect(page).to have_content(edit_establish_success_message_text)
      expect(current_url).to include("/decision_reviews/vha?tab=in_progress")

      expect(task.reload.status).to eq("assigned")
    end
  end

  shared_examples "Vha HLR/SC adding issue without decision date to existing claim review" do
    it "Allows Vha to add an issue without a decision date to an existing claim review and remove the issue" do
      visit edit_url

      expect(task.status).to eq("assigned")
      expect(page).to have_button("Establish", disabled: true)

      click_intake_add_issue
      add_intake_nonrating_issue(
        category: "Beneficiary Travel",
        description: "Travel for VA meeting",
        date: nil
      )

      click_intake_add_issue
      add_intake_nonrating_issue(
        category: "CHAMPVA",
        description: "CHAMPVA issue",
        date: nil
      )

      click_intake_add_issue
      add_intake_nonrating_issue(
        category: "Clothing Allowance",
        description: "Clothes for dependent",
        date: nil
      )

      expect(page).to have_content(COPY::VHA_NO_DECISION_DATE_BANNER)

      click_button "Save"

      expect(page).to have_content(COPY::CORRECT_REQUEST_ISSUES_CHANGED_MODAL_TITLE)

      click_button "Yes, save"

      expect(page).to have_content(COPY::VHA_INCOMPLETE_TAB_DESCRIPTION)
      expect(current_url).to include("/decision_reviews/vha?tab=incomplete")
      expect(page).to have_content(edit_save_success_message_text)
      expect(task.reload.status).to eq("on_hold")

      # Go back to the Edit issues page
      click_link task.appeal.veteran.name.to_s

      expect(page).to have_button("Save", disabled: true)

      expect(page).to have_content(COPY::VHA_NO_DECISION_DATE_BANNER)

      # Add a decision date, remove an issue, and withdraw an issue
      new_issues = task.appeal.request_issues.reload.select { |issue| issue.decision_date.blank? }
      request_issue_id = new_issues.first.id
      second_issue_id = new_issues.second.id
      third_issue_id = new_issues.third.id

      within "#issue-#{request_issue_id}" do
        first("select").select("Add decision date")
      end

      fill_in "decision-date", with: (Time.zone.now - 1.week).strftime("%m/%d/%Y")

      within ".cf-modal-controls" do
        expect(page).to have_button("Save", disabled: false)
        click_on("Save")
      end

      expect(page).to have_content(changed_issue_banner_save_text)

      click_button "Save"

      expect(page).to have_content(edit_decision_date_success_message_text)
      expect(current_url).to include("/decision_reviews/vha?tab=incomplete")
      expect(task.reload.status).to eq("on_hold")

      # Go back to the Edit issues page
      click_link task.appeal.veteran.name.to_s

      expect(page).to have_button("Save", disabled: true)
      expect(page).to have_content(COPY::VHA_NO_DECISION_DATE_BANNER)

      within "#issue-#{second_issue_id}" do
        first("select").select("Remove issue")
      end

      click_on("Yes, remove issue")

      expect(page).to have_content(changed_issue_banner_save_text)
      expect(page).to have_content(COPY::VHA_NO_DECISION_DATE_BANNER)

      within "#issue-#{third_issue_id}" do
        first("select").select("Withdraw issue")
      end

      expect(page).to have_content(changed_issue_banner_establish_text)
      expect(page).to have_button("Establish", disabled: true)

      fill_in "withdraw-date", with: (Time.zone.now - 1.week).strftime("%m/%d/%Y")

      expect(page).to have_button("Establish", disabled: false)
      expect(page).to_not have_content(COPY::VHA_NO_DECISION_DATE_BANNER)

      within "#issue-#{third_issue_id}" do
        expect(page).to_not have_content("Select action")
      end

      click_button "Establish"

      expect(page).to have_content(COPY::CORRECT_REQUEST_ISSUES_CHANGED_MODAL_TITLE)

      click_button "Yes, save"

      expect(page).to have_content(edit_establish_success_message_text)
      expect(current_url).to include("/decision_reviews/vha?tab=in_progress")
      expect(task.reload.status).to eq("assigned")
    end
  end

  context "creating Supplemental Claims with no decision date" do
    let(:intake_type) do
      start_supplemental_claim(veteran, benefit_type: "vha")
    end

    let(:intake_button_text) { "Save Supplemental Claim" }
    let(:success_message_text) { "You have successfully saved #{veteran.name}'s #{SupplementalClaim.review_title}" }
    let(:edit_establish_success_message_text) do
      "You have successfully established #{veteran.name}'s #{SupplementalClaim.review_title}"
    end

    it_behaves_like "Vha HLR/SC Issue without decision date"
  end

  context "creating Higher Level Reviews with no decision date" do
    let(:intake_type) do
      start_higher_level_review(veteran, benefit_type: "vha")
    end

    let(:intake_button_text) { "Save Higher-Level Review" }
    let(:success_message_text) { "You have successfully saved #{veteran.name}'s #{HigherLevelReview.review_title}" }
    let(:edit_establish_success_message_text) do
      "You have successfully established #{veteran.name}'s #{HigherLevelReview.review_title}"
    end

    it_behaves_like "Vha HLR/SC Issue without decision date"
  end

  context "adding an issue without a decision date to an existing HLR/SC" do
    before do
      task.appeal.establish!
    end

    let(:claim_review) do
      task.appeal
    end

    let(:edit_decision_date_success_message_text) do
      "You have successfully updated an issue's decision date"
    end

    let(:edit_save_success_message_text) do
      "You have successfully added 3 issues."
    end

    context "an existing Higher-Level Review" do
      let(:task) do
        FactoryBot.create(:higher_level_review_vha_task, assigned_to: VhaBusinessLine.singleton)
      end

      let(:edit_url) do
        "/higher_level_reviews/#{claim_review.uuid}/edit"
      end

      let(:edit_establish_success_message_text) do
        "You have successfully established #{claim_review.veteran.name}'s #{HigherLevelReview.review_title}"
      end

      it_behaves_like "Vha HLR/SC adding issue without decision date to existing claim review"
    end

    context "an existing Supplmental Claim" do
      let(:task) do
        FactoryBot.create(:supplemental_claim_vha_task, assigned_to: VhaBusinessLine.singleton)
      end

      let(:edit_url) do
        "/supplemental_claims/#{claim_review.uuid}/edit"
      end

      let(:edit_establish_success_message_text) do
        "You have successfully established #{claim_review.veteran.name}'s #{SupplementalClaim.review_title}"
      end

      it_behaves_like "Vha HLR/SC adding issue without decision date to existing claim review"
    end
  end
end
