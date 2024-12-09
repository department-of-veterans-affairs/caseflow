# frozen_string_literal: true

RSpec.feature("The Correspondence Intake page") do
  include CorrespondenceHelpers
  include CorrespondenceTaskHelpers
  alias_method :create_efolderupload_task, :create_efolderupload_failed_task

  let(:organization) { InboundOpsTeam.singleton }
  let(:mail_user) { User.authenticate!(roles: ["Mail Team"]) }
  let(:supervisor_user) { create(:inbound_ops_team_supervisor) }
  let(:unauthorized_user) { create(:user) }
  let(:correspondence) { create :correspondence, :with_correspondence_intake_task, assigned_to: mail_user }
  let(:correspondence_intake_task) { correspondence.open_intake_task }
  context "correspondence intake form access" do
    before :each do
      Bva.singleton.add_user(unauthorized_user)
      User.authenticate!(user: unauthorized_user)
    end

    it "routes unauthorized user to /unauthorized if feature toggle is disabled" do
      FeatureToggle.disable!(:correspondence_queue)
      visit "/queue/correspondence/#{correspondence.uuid}/intake"
      expect(page).to have_current_path("/unauthorized")
    end

    it "routes unauthorized user to /unauthorized if feature toggle enabled" do
      FeatureToggle.disable!(:correspondence_queue)
      visit "/queue/correspondence/#{correspondence.uuid}/intake"
      expect(page).to have_current_path("/unauthorized")
    end
  end

  before :each do
    organization.add_user(mail_user)
    mail_user.reload
    # reload in case of controller validation triggers before data created
    correspondence_intake_task.reload
  end

  context "intake form feature toggle" do
    it "routes user to /under_construction if the feature toggle is disabled" do
      FeatureToggle.disable!(:correspondence_queue)
      User.authenticate!(user: mail_user)
      visit "/queue/correspondence/#{correspondence.uuid}/intake"
      expect(page).to have_current_path("/under_construction")
    end

    it "routes to intake if feature toggle is enabled" do
      FeatureToggle.enable!(:correspondence_queue)
      visit "/queue/correspondence/#{correspondence.uuid}/intake"
      expect(page).to have_current_path("/queue/correspondence/#{correspondence.uuid}/intake")
    end
  end

  context "intake form shell" do
    before :each do
      User.authenticate!(user: supervisor_user)
      setup_and_visit_intake
    end

    it "the intake page exists" do
      expect(page).to have_current_path("/queue/correspondence/#{correspondence.uuid}/intake")
    end

    it "successfully navigates on return to queue and save intake" do
      click_on("button-Return-to-queue")
      page.all(".cf-form-radio-option")[3].click
      click_on("Return-To-Queue-button-id-1")
      using_wait_time(20) do
        expect(page).to have_content("You have successfully saved the intake form")
      end
    end

    it "successfully advances to the second step" do
      click_on("button-continue")
      expect(page).to have_button("Continue")
      expect(page).to have_button("Back")
      expect(page).to have_no_button("Submit")
    end

    it "successfully advances to the final step" do
      click_on("button-continue")
      click_on("button-continue")
      expect(page).to have_button("Submit")
      expect(page).to have_button("Back")
      expect(page).to have_no_button("Continue")
    end

    it "successfully returns to the first step" do
      click_on("button-continue")
      click_on("button-back-button")

      expect(page).to have_button("Continue")
      expect(page).to have_no_button("Back")
      expect(page).to have_no_button("Submit")
    end

    it "successfully returns to the second step" do
      click_on("button-continue")
      click_on("button-continue")
      click_on("button-back-button")

      expect(page).to have_button("Continue")
      expect(page).to have_button("Back")
      expect(page).to have_no_button("Submit")
    end
  end

  context "access 'Tasks not Related to an Appeals'" do
    before :each do
      setup_and_visit_intake
    end

    it "Paragraph text appears below the title" do
      click_on("button-continue")
      expect(page).to have_button("+ Add tasks")
      expect(page).to have_text("Add new tasks related to this correspondence or " \
        "to an appeal not yet created in Caseflow.")
    end
  end

  context "The mail team user is able to add unrelated tasks" do
    before :each do
      setup_and_visit_intake
      click_on("button-continue")
    end

    it "The user can add additional tasks to correspondence by selecting the '+add tasks' button again" do
      click_on("+ Add tasks")
      expect(page).to have_button("+ Add tasks")
    end

    it "Four tasks is the limit for the user" do
      click_on("+ Add tasks")
      click_on("+ Add tasks")
      click_on("+ Add tasks")
      click_on("+ Add tasks")
      expect(page).to have_button("+ Add tasks", disabled: true)
    end

    it "Two 'Other Motion' tasks is the limit for user" do
      click_on("+ Add tasks")
      all("#reactSelectContainer")[0].click
      find_by_id("react-select-2-option-4").click
      expect(page).to have_content("Other Motion")
      click_on("+ Add tasks")
      all("#reactSelectContainer")[1].click
      find_by_id("react-select-3-option-4").click
      within all("#reactSelectContainer")[1] do
        expect(page).to have_content("Other Motion")
      end
      expect(page).to have_button("+ Add tasks", disabled: false)
    end

    it "Two unrelated tasks have been added" do
      click_on("+ Add tasks")
      expect(page).to have_text("Please provide context and instructions for this action")
      expect(page.all(".cf-form-textarea").count).to eq(1)
      click_on("+ Add tasks")
      expect(page.all(".cf-form-textarea").count).to eq(2)
    end

    it "Closes out new section when unrelated tasks have been removed" do
      click_on("+ Add tasks")
      expect(page).to have_text("Please provide context and instructions for this action")
      click_on("button-Remove")
      expect(page).to_not have_text("New Tasks")
    end

    it "Disables continue button when task is added" do
      click_on("+ Add tasks")
      expect(page).to have_text("Please provide context and instructions for this action")
      expect(page).to have_button("button-continue", disabled: true)
    end

    it "Re-enables continue button when all new task has been filled out" do
      click_on("+ Add tasks")
      all("#reactSelectContainer")[0].click
      find_by_id("react-select-2-option-1").click
      expect(page).to have_button("button-continue", disabled: true)
      find_by_id("content").fill_in with: "Correspondence Text"
      expect(page).to have_button("button-continue", disabled: false)
    end

    it "Re populates fields after going back a step and then continuing forward again" do
      click_on("+ Add tasks")
      all("#reactSelectContainer")[0].click
      find_by_id("react-select-2-option-0").click
      find_by_id("content").fill_in with: "Correspondence test text"
      click_button("button-back-button")
      click_button("button-continue")
      expect(page).to have_button("button-continue", disabled: false)
      expect(page).to have_content("CAVC Correspondence")
      expect(page).to have_content("Correspondence test text")
    end
  end

  context "Step 3 - Confirm" do
    before :each do
      inbound_ops_team_admin_setup
    end

    describe "Tasks not related to an Appeal section" do
      it "displays the correct content" do
        visit_intake_form_step_3_with_tasks_unrelated

        expect(page).to have_content("Tasks not related to an Appeal")
        expect(all("button > span", text: "Edit Section").length).to eq(5)
        expect(page).to have_content("Tasks")
        expect(page).to have_content("Task Instructions or Context")
        expect(page).to have_content("CAVC Correspondence")
        expect(page).to have_content("Correspondence test text")
      end

      it "Edit section link returns user to Tasks not related to an Appeal on Step 2" do
        visit_intake_form_step_3_with_tasks_unrelated
        all("button > span", text: "Edit Section")[2].click
        expect(page).to have_content("Review Tasks & Appeals")
        expect(page).to have_content("Tasks not related to an Appeal")
      end
    end
  end

  context "The user is able to use the autotext feature" do
    before do
      seed_autotext_table
    end

    before :each do
      setup_and_visit_intake
      click_on("button-continue")
      click_on("+ Add tasks")
    end

    it "The user can open the autotext modal" do
      find_by_id("addAutotext").click
      within find_by_id("autotextModal") do
        expect(page).to have_text("Cancel")
      end
    end

    it "The user can close the modal with the cancel button." do
      find_by_id("addAutotext").click
      within find_by_id("autotextModal") do
        expect(page).to have_text("Cancel")
      end
      find_by_id("Add-autotext-button-id-0").click
      cancel_count = all("#button-Return-to-queue").length
      expect(cancel_count).to eq 1
    end

    it "The user can close the modal with the x button located in the top right." do
      find_by_id("addAutotext").click
      within find_by_id("autotextModal") do
        expect(page).to have_text("Cancel")
      end
      find(".cf-icon-close").click
      cancel_count = all("#button-Return-to-queue").length
      expect(cancel_count).to eq 1
    end

    it "Clears all selected options in modal" do
      find_by_id("addAutotext").click
      within find_by_id("autotextModal") do
        expect(page).to have_text("Clear all")
      end
      within find_by_id("autotextModal") do
        page.all(".cf-form-checkbox")[2].click
        page.all(".cf-form-checkbox")[4].click
        expect(find_field("Interest noted in telephone call of mm/dd/yy", visible: false)).to be_checked
        expect(find_field("Email - responded via email on mm/dd/yy", visible: false)).to be_checked
        find_by_id("Add-autotext-button-id-2").click
        expect(find_field("Interest noted in telephone call of mm/dd/yy", visible: false)).to_not be_checked
        expect(find_field("Email - responded via email on mm/dd/yy", visible: false)).to_not be_checked
      end
    end

    it "The user is able to add manual text content" do
      fill_in "content", with: "debug data for autofill"
      expect(find_by_id("content").text).to eq "debug data for autofill"
    end

    it "The user is able to add autotext" do
      find_by_id("addAutotext").click
      checkbox_text = "Possible motion pursuant to BVA decision dated mm/dd/yy"
      within find_by_id("autotextModal") do
        page.all(".cf-form-checkbox")[6].click
        find_by_id("Add-autotext-button-id-1").click
      end
      expect(find_by_id("content").text).to eq checkbox_text
    end

    it "Allows multiple autotext options to be selected" do
      find_by_id("addAutotext").click
      checkbox_text_1 = "Decision sent to Senator or Congressman mm/dd/yy"
      checkbox_text_6 = "Possible motion pursuant to BVA decision dated mm/dd/yy"
      within find_by_id("autotextModal") do
        page.all(".cf-form-checkbox")[1].click
        page.all(".cf-form-checkbox")[6].click
        find_by_id("Add-autotext-button-id-1").click
      end
      expect(find_by_id("content").text).to include checkbox_text_1 && checkbox_text_6
    end

    it "Allows autotext and manual text input" do
      manual_text = "This is a test"
      fill_in "content", with: "This is a test\n"
      expect(find_by_id("content").text).to eq manual_text
      find_by_id("addAutotext").click
      checkbox_text = "Possible motion pursuant to BVA decision dated mm/dd/yy"
      within find_by_id("autotextModal") do
        page.all(".cf-form-checkbox")[6].click
        find_by_id("Add-autotext-button-id-1").click
      end
      expect(find_by_id("content").text).to include manual_text && checkbox_text
    end

    it "Persists data if the user hits the back button, then returns" do
      find_by_id("addAutotext").click
      checkbox_text = "Possible motion pursuant to BVA decision dated mm/dd/yy"
      within find_by_id("autotextModal") do
        page.all(".cf-form-checkbox")[6].click
        find_by_id("Add-autotext-button-id-1").click
      end
      click_on("button-back-button")
      click_on("button-continue")
      expect(find_by_id("content").text).to eq checkbox_text
    end
  end

  context "correspondence tasks in-progress tab and navigate to step 3 when we click on intake task" do
    let(:current_user) { create(:user) }
    before :each do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    before do
      FeatureToggle.enable!(:correspondence_queue)

      correspondence = create(:correspondence)
      create_correspondence_intake(correspondence, current_user)
      correspondence.tasks.find_by(type: CorrespondenceIntakeTask.name).reload
    end

    it "successfully loads the in progress tab" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Correspondence in progress")
    end

    it "navigates to intake form from in-progress tab to step 3" do
      visit "/queue/correspondence?tab=correspondence_in_progress"
      find("#task-link").click
      click_on("button-continue")
      click_on("button-continue")
      intake_path = current_path
      click_on("button-Return-to-queue")
      page.all(".cf-form-radio-option")[1].click
      click_on("Return-To-Queue-button-id-1")
      using_wait_time(20) do
        expect(page).to have_content("You have successfully saved the intake form")
      end
      visit "/queue/correspondence?tab=correspondence_in_progress"
      find("#task-link").click
      expect(current_path).to eq(intake_path)
      expect(page).to have_content("Review and Confirm Correspondence")
    end
  end

  context "checks for failed to upload to the eFolder banner after navigating away from page" do
    let(:current_user) { create(:user) }
    before do
      InboundOpsTeam.singleton.add_user(supervisor_user)
      MailTeam.singleton.add_user(supervisor_user)
      User.authenticate!(user: supervisor_user)
      FeatureToggle.enable!(:correspondence_queue)

      5.times do
        correspondence = create(:correspondence)
        parent_task = create_correspondence_intake(correspondence, supervisor_user)
        create_efolderupload_task(correspondence, parent_task)
      end
    end

    it "successfully loads the assigned tab" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Correspondence that is currently assigned to mail team users")
    end

    it "navigates to intake form from in-progress tab to step 3 and checks for failed to upload to the eFolder banner" \
       " from the Centralized Mail Portal, if it needs to be processed." do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned&page=1&sort_by=vaDor&order=asc"
      find("tbody > tr:last-child > td:nth-child(2)").click
      using_wait_time(15) do
        click_on("button-continue")
      end
      click_on("button-continue")
      click_on("Submit")
      click_on("Confirm")
      expect(page).to have_content("The correspondence's documents have failed to upload to the eFolder")
      intake_path = current_path
      click_on("button-Return-to-queue")
      page.all(".cf-form-radio-option")[1].click
      click_on("Return-To-Queue-button-id-1")
      using_wait_time(15) do
        expect(page).to have_content("You have successfully saved the intake form")
      end
      visit intake_path
      using_wait_time(30) do
        expect(page).to have_content("The correspondence's documents have failed to upload to the eFolder")
      end
    end
  end
end
