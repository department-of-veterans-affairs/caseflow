# frozen_string_literal: true

RSpec.feature("The Correspondence Review Pacakage page") do
  context "Review package form shell" do
    before :each do
      User.authenticate!(roles: ["Mail Intake"])
      @correspondence_uuid = "123456789"
      visit "/queue/correspondences/#{@correspondence_uuid}/review_package"
    end

    it "the Review package page exists" do
      expect(page).to have_current_path("/queue/correspondences/#{@correspondence_uuid}/review_package")
    end

    it "successfully navigates on cancel link click" do
      click_on("button-Cancel")
      expect(page).to have_current_path("/queue/correspondences")
    end

    it "on click of create record button successfully navigates to intake page" do
      visit "/queue/correspondences/#{@correspondence_uuid}/review_package"
      click_on("button-Create-record")
      FeatureToggle.enable(:correspondence_queue)
      expect(page).to have_current_path("/queue/correspondence/#{@correspondence_uuid}/intake")
    end

    it "Checking the buttons" do
      expect(page).to have_button("Cancel")
      expect(page).to have_button("Intake appeal")
      expect(page).to have_button("Create record")
    end
  end
end
