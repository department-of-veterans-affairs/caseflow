# frozen_string_literal: true

RSpec.feature("The Correspondence Intake page") do
  include CorrespondenceHelpers
  let(:organization) { MailTeam.singleton }
  let(:mail_user) { User.authenticate!(roles: ["Mail Team"]) }
  let(:unauthorized_user) { create(:user) }

  context "correspondence intake form access" do
    before :each do
      Bva.singleton.add_user(unauthorized_user)
      User.authenticate!(user: unauthorized_user)
    end

    it "routes unauthorized user to /unauthorized if feature toggle is disabled" do
      FeatureToggle.disable!(:correspondence_queue)
      visit "/queue/correspondence/#{@correspondence_uuid}/intake"
      expect(page).to have_current_path("/unauthorized")
    end

    it "routes unauthorized user to /unauthorized if feature toggle enabled" do
      FeatureToggle.disable!(:correspondence_queue)
      visit "/queue/correspondence/#{@correspondence_uuid}/intake"
      expect(page).to have_current_path("/unauthorized")
    end
  end

  before :each do
    organization.add_user(mail_user)
    mail_user.reload
  end

  context "intake form feature toggle" do
    before :each do
      veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
      create(
        :correspondence,
        veteran_id: veteran.id,
        uuid: SecureRandom.uuid,
        va_date_of_receipt: Time.zone.local(2023, 1, 1)
      )
      @correspondence_uuid = Correspondence.first.uuid
    end

    it "routes user to /under_construction if the feature toggle is disabled" do
      FeatureToggle.disable!(:correspondence_queue)
      User.authenticate!(user: mail_user)
      visit "/queue/correspondence/#{@correspondence_uuid}/intake"
      expect(page).to have_current_path("/under_construction")
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
      veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
      create(
        :correspondence,
        veteran_id: veteran.id,
        uuid: SecureRandom.uuid,
        va_date_of_receipt: Time.zone.local(2023, 1, 1)
      )
      @correspondence_uuid = Correspondence.first.uuid
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
      veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
      create(
        :correspondence,
        veteran_id: veteran.id,
        uuid: SecureRandom.uuid,
        va_date_of_receipt: Time.zone.local(2023, 1, 1)
      )
      @correspondence_uuid = Correspondence.first.uuid
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
      veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
      create(
        :correspondence,
        veteran_id: veteran.id,
        uuid: SecureRandom.uuid,
        va_date_of_receipt: Time.zone.local(2023, 1, 1)
      )

      @correspondence_uuid = Correspondence.first.uuid
      visit "/queue/correspondence/#{@correspondence_uuid}/intake"
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
      expect(page).to have_content("Other motion")
      click_on("+ Add tasks")
      all("#reactSelectContainer")[1].click
      find_by_id("react-select-3-option-4").click
      within all("#reactSelectContainer")[1] do
        expect(page).to have_content("Other motion")
      end
      expect(page).to have_button("+ Add tasks", disabled: false)
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
    describe "Tasks not related to an Appeal section" do
      it "displays the correct content" do
        visit_intake_form_step_3_with_tasks_unrelated

        expect(page).to have_content("Tasks not related to an Appeal")
        expect(all("button > span", text: "Edit Section").length).to eq(3)
        expect(page).to have_content("Tasks")
        expect(page).to have_content("Task Instructions or Context")
        expect(page).to have_content("CAVC Correspondence")
        expect(page).to have_content("Correspondence test text")
      end

      it "Edit section link returns user to Tasks not related to an Appeal on Step 2" do
        visit_intake_form_step_3_with_tasks_unrelated
        all("button > span", text: "Edit Section")[1].click
        expect(page).to have_content("Review Tasks & Appeals")
        expect(page).to have_content("Tasks not related to an Appeal")
      end
    end
  end

  context "The user is able to use the autotext feature" do
    before do
      require Rails.root.join("db/seeds/base.rb").to_s
      Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |f| require f }
      Seeds::AutoTexts.new.seed!
    end

    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
      create(
        :correspondence,
        veteran_id: veteran.id,
        uuid: SecureRandom.uuid,
        va_date_of_receipt: Time.zone.local(2023, 1, 1)
      )
      @correspondence_uuid = Correspondence.first.uuid
      visit "/queue/correspondence/#{@correspondence_uuid}/intake"
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
      cancel_count = all("#button-Cancel").length
      expect(cancel_count).to eq 1
    end

    it "The user can close the modal with the x button located in the top right." do
      find_by_id("addAutotext").click
      within find_by_id("autotextModal") do
        expect(page).to have_text("Cancel")
      end
      find_by_id("Add-autotext-button-id-close").click
      cancel_count = all("#button-Cancel").length
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
end
