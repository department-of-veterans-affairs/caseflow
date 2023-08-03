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
    end
  end

  context "creating Supplemental Claims with no decision date" do
    let(:intake_type) do
      start_supplemental_claim(veteran, benefit_type: "vha")
    end

    let(:intake_button_text) { "Save Supplemental Claim" }
    let(:success_message_text) { "You have successfully saved #{veteran.name}'s Supplemental Claim" }

    it_behaves_like "Vha HLR/SC Issue without decision date"
  end

  context "creating Higher Level Reviews with no decision date" do
    let(:intake_type) do
      start_higher_level_review(veteran, benefit_type: "vha")
    end
    let(:intake_button_text) { "Save Higher-Level Review" }
    let(:success_message_text) { "You have successfully saved #{veteran.name}'s Higher-Level Review" }

    it_behaves_like "Vha HLR/SC Issue without decision date"
  end
end
