# frozen_string_literal: true

RSpec.feature("The Correspondence Intake page") do
  include CorrespondenceHelpers
  context "intake form feature toggle" do
    before :each do
      User.authenticate!(roles: ["Mail Intake"])
      @correspondence_uuid = "123456789"
    end

    it "routes user to /unauthorized if the feature toggle is disabled" do
      FeatureToggle.disable!(:correspondence_queue)
      visit "/queue/correspondence/#{@correspondence_uuid}/intake"
      expect(page).to have_current_path("/unauthorized")
    end

    it "routes to intake if feature toggle is enabled" do
      FeatureToggle.enable!(:correspondence_queue)
      visit "/queue/correspondence/#{@correspondence_uuid}/intake"
      expect(page).to have_current_path("/queue/correspondence/#{@correspondence_uuid}/intake")
    end
  end

  context "intake form shell" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      User.authenticate!(roles: ["Mail Intake"])
      @correspondence_uuid = "123456789"
      visit "/queue/correspondence/#{@correspondence_uuid}/intake"
    end

    it "the intake page exists" do
      expect(page).to have_current_path("/queue/correspondence/#{@correspondence_uuid}/intake")
    end

    it "successfully navigates on cancel link click" do
      click_on("button-Cancel")
      expect(page).to have_current_path("/queue/correspondence")
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
      FeatureToggle.enable!(:correspondence_queue)
      User.authenticate!(roles: ["Mail Intake"])
      @correspondence_uuid = "0c77d6d2-c19f-4dbb-8e79-919a4090ed33"
      visit "/queue/correspondence/#{@correspondence_uuid}/intake"
    end

    it "Paragraph text appears below the title" do
      click_on("button-continue")
      expect(page).to have_button("+ Add tasks")
      expect(page).to have_text("Add new tasks related to this correspondence or " +
        "to an appeal not yet created in Caseflow.")
    end
  end

  context "The mail team user is able to add unrelated tasks" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      User.authenticate!(roles: ["Mail Intake"])
      @correspondence_uuid = SecureRandom.uuid
      visit "/queue/correspondence/#{@correspondence_uuid}/intake"
      click_on("button-continue")
    end

    it "The user can add additional tasks to correspondence by selecting the '+add tasks' button again" do
      click_on("+ Add tasks")
      expect(page).to have_button("+ Add tasks")
    end

    it "Two tasks is the limit for the user" do
      click_on("+ Add tasks")
      click_on("+ Add tasks")
      expect(page).to have_button("+ Add tasks", disabled: true)
    end

    it "Two unrelated tasks have been added" do
      click_on("+ Add tasks")
      expect(page).to have_text("Provide context and instruction on this task")
      expect(page.all(".cf-form-textarea").count).to eq(1)
      click_on("+ Add tasks")
      expect(page.all(".cf-form-textarea").count).to eq(2)
    end

    it "Closes out new section when unrelated tasks have been removed" do
      click_on("+ Add tasks")
      expect(page).to have_text("Provide context and instruction on this task")
      click_on("button-Remove")
      expect(page).to_not have_text("New Tasks")
    end

    it "Disables continue button when task is added" do
      click_on("+ Add tasks")
      expect(page).to have_text("Provide context and instruction on this task")
      expect(page).to have_button("button-continue", disabled: true)
    end

    it "Re-enables continue button when all new task has been filled out" do
      click_on("+ Add tasks")
      page.find(:xpath, '//*[@id="reactSelectContainer"]/div/div').click
      page.find("#react-select-2-input").fill_in with: "CAVC Correspondence"
      page.find(".css-e42auv", text: "CAVC Correspondence").click
      expect(page).to have_button("button-continue", disabled: true)
      find_by_id("content").fill_in with: "Correspondence Text"
      expect(page).to have_button("button-continue", disabled: false)
    end

    it "Re populates feilds after going back a step and then continuing forward again" do
      click_on("+ Add tasks")
      find_by_id("reactSelectContainer").click
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
    describe "Tasks not related to an Appeal section" do
      it "displays the correct content" do
        visit_intake_form_step_3_with_tasks_unrelated

        expect(page).to have_content("Tasks not related to an Appeal")
        expect(page).to have_link("Edit section")
        within(".usa-table-borderless") do
          expect(page).to have_content("Tasks")
          expect(page).to have_content("Task Instructions or Context")
          expect(page).to have_content("CAVC Correspondence")
          expect(page).to have_content("Correspondence test text")
        end
      end

      it "Edit section link returns user to Tasks not related to an Appeal on Step 2" do
        visit_intake_form_step_3_with_tasks_unrelated
        click_link("Edit section")
        expect(page).to have_content("Review Tasks & Appeals")
        expect(page.current_url.include?("#task-not-related-to-an-appeal")).to eq(true)
      end
    end
  end
end
