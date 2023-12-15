# frozen_string_literal: true

RSpec.feature("The Correspondence Intake page") do
  include CorrespondenceHelpers
  let(:organization) { MailTeam.singleton }
  let(:mail_user) { User.authenticate!(roles: ["Mail Team"]) }

    before do
      organization.add_user(mail_user)
      mail_user.reload
  end

  context "Mail Tasks Confirm Page" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      # User.authenticate!(roles: ["Mail Intake"])
      @correspondence_uuid = "123456789"
      # @correspondence_uuid = "0c77d6d2-c19f-4dbb-8e79-919a4090ed33"
      visit "/queue/correspondence/#{@correspondence_uuid}/intake"
    end

    it "the intake page exists" do
      expect(page).to have_current_path("/queue/correspondence/#{@correspondence_uuid}/intake")
    end

    it "successfully advances to the second step" do
      click_on("button-continue")
      expect(page).to have_button("Continue")
      expect(page).to have_button("Back")
      expect(page).to have_no_button("Submit")
    end

    it "Displays the expected content for Mail Tasks" do
      click_on("button-continue")
      expect(page).to have_text("Review Tasks & Appeals")
      expect(page).to have_text("Mail Tasks")
      expect(page).to have_text("Select any tasks completed by the Mail team for this correspondence.")
    end

    it "Can able to select any Mail tasks from both pannel" do
      click_on("button-continue")
      checkbox_div = page.find(:xpath, '//*[@id="mail-tasks-left"]')
      checkboxes = checkbox_div.all(".cf-form-checkbox ")[0..2].each { |cb| cb.set(true) }
      expect(checkboxes.size).to eq(3)
      checkbox_div = page.find(:xpath, '//*[@id="mail-tasks-right"]')
      checkboxes = checkbox_div.all(".cf-form-checkbox ")[0..2].each { |cb| cb.set(true) }
      expect(checkboxes.size).to eq(3)
    end

    it "Select Mail Tasks and Submit" do
      click_on("button-continue")
      checkbox_div = page.find(:xpath, '//*[@id="mail-tasks-left"]')
      checkbox_div.all(".cf-form-checkbox ")[0..2].each { |cb| cb.set(true) }
      click_on("button-continue")
      expect(page).to have_text("Review and Confirm Correspondence")
      expect(page).to have_text("Completed Mail Tasks")
      expect(page).to have_text("Change of address")
      expect(page).to have_button("Edit Section")
      click_button("button-EditMailTasks", visible:"false")
      expect(page).to have_text("Mail Tasks")
      checkbox = all("#mail-tasks-left .cf-form-checkbox")[0]
      checkbox_input = checkbox.find('input[name="Change of address"]', visible: :all)
      expect(checkbox_input).to be_checked
    end
  end
end
