# frozen_string_literal: true

RSpec.feature("The Correspondence Intake page") do
  context "intake form shell" do
    before :each do
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
end
