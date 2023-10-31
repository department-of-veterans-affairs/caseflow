# frozen_string_literal: true

RSpec.feature("The Correspondence Cases page") do
  context "correspondece cases feature toggle" do
    before :each do
      User.authenticate!(roles: ["Mail Intake"])
      @correspondence_uuid = "123456789"
    end

    it "routes user to /unauthorized if the feature toggle is disabled" do
      FeatureToggle.disable!(:correspondence_queue)
      visit "/queue/correspondence"
      expect(page).to have_current_path("/unauthorized")
    end

    it "routes to correspondence cases if feature toggle is enabled" do
      FeatureToggle.enable!(:correspondence_queue)
      visit "/queue/correspondence"
      expect(page).to have_current_path("/queue/correspondence")
    end
  end

  context "correspondence cases form shell" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      User.authenticate!(roles: ["Mail Intake"])
      @correspondence_uuid = "123456789"
      visit "/queue/correspondence"
    end

    it "go to correspondence cases" do
      visit "/queue"
      click_on("Switch views")
      click_on(format(COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_CORRESPONDENCE_CASES))
      expect(page).to have_current_path("/queue/correspondence")
    end

    it "the correspondece cases page exists" do
      expect(page).to have_current_path("/queue/correspondence")
      expect(page).to have_content(format(COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_CORRESPONDENCE_CASES))
    end
  end
end
