# frozen_string_literal: true

RSpec.feature("The Correspondence Review Pacakage page") do
  context "Review package feature toggle" do
    before :each do
      User.authenticate!(roles: ["Mail Intake"])
      @correspondence_uuid = "123456789"
    end

    it "routes user to /unauthorized if the feature toggle is disabled" do
      FeatureToggle.disable!(:correspondence_queue)
      visit "/queue/correspondence/#{@correspondence_uuid}/review_package"
      expect(page).to have_current_path("/unauthorized")
    end
  end

  context "Review package form shell" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      User.authenticate!(roles: ["Mail Intake"])
      @correspondence_uuid = "123456789"
      visit "/queue/correspondence/#{@correspondence_uuid}/review_package"
    end

    it "the Review package page exists" do
      expect(page).to have_current_path("/queue/correspondence/#{@correspondence_uuid}/review_package")
    end
    it "check for CMP Edit button" do
      expect(page).to have_content("Edit")
      click_button "Edit"
    end
    it "the save button is disabled at first" do
      expect(page).to have_field("VA DOR", with: decision_date)
      expect(page).to have_field("Package document type")
      expect(page).to have_button("Cancel")
      expect(page).to have_button("Save", disabled: true)
    end
  end
end
