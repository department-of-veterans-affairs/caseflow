# frozen_string_literal: true

feature "Vha Higher-Level Review and Supplemental Claims Enter No Decision Date", :all_dbs do
  include IntakeHelpers

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:veteran_file_number) { "123412345" }

  let(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number,
                              first_name: "Ed",
                              last_name: "Merica")
  end

  shared_examples "Vha HLR/SC Issue without decision date" do
    it "Allows Vha to save a claim review with an issue without a decision date" do
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

      # Check to make sure that the task that was created is on hold?
      task = DecisionReviewTask.last
      expect(task.status).to eq("on_hold")

      # Click the link and check to make sure that we are now on the edit issues page
      click_link veteran.name.to_s

      expect(page).to have_content("Edit Issues")
      expect(page).to have_content("Decision date: No date entered")
      expect(page).to have_content(COPY::VHA_NO_DECISION_DATE_BANNER)

      # TODO: Add more stuff after editing is working
      # Hit the first and add a decision date
      expect(page).to have_button("Save", disabled: true)

      # within "#issue-0" do
      #   select("Add decision date", from: "issue-action-0")
      # end

      # future_date = Time.zone.now + 1.week.to_s
      # past_date = Time.zone.now - 1.week

      # fill_in "decision_date", with: future_date

      # # This should be the decision date modal button instead of the previous button
      # # The button should be disabled since the date is in the future
      # expect(page).to have_button("Save", disabled: true)

      # fill_in "decision date", with: past_date

      # # Make sure this is the correct button
      # click_on("Save")

      # # Check that the Edit Issues save button is now establish
      # expect(page).to have_content("Decision date: #{past_date.to_date}")
      # expect(page).to have_button("Establish", disabled: false)

      # click_on("Establish")

      # # task should now be assigned and on the in progress tab
      # expect(page).to_not have_content(COPY::VHA_INCOMPLETE_TAB_DESCRIPTION)
      # expect(page).to have_content(edit_establish_success_message_text)
      # expect(current_url).to include("/decision_reviews/vha?tab=in_progress")

      # task.reload
      # expect(task.status).to eq("assigned")
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
end
