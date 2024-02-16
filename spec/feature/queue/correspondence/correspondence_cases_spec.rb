# frozen_string_literal: true

RSpec.feature("The Correspondence Cases page") do
  include CorrespondenceTaskHelpers
  context "correspondece cases feature toggle" do
    let(:current_user) { create(:user) }
    before :each do
      MailTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      @correspondence_uuid = "123456789"
    end

    it "routes user to /under_construction if the feature toggle is disabled" do
      FeatureToggle.disable!(:correspondence_queue)
      visit "/queue/correspondence"
      expect(page).to have_current_path("/under_construction")
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
      User.authenticate!(user: current_user)
      @correspondence_uuid = "123456789"
    end
  end

  context "correspondence tasks in-progress tab" do
    let(:current_user) { create(:user) }
    before :each do
      MailTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end
    before do
      20.times do
        correspondence = create(:correspondence)
        parent_task = create_correspondence_intake(correspondence, current_user)
        create_efolderupload_failed_task(correspondence, parent_task, user: current_user)
      end
    end
    it "is my tests" do
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"

      binding.pry
    end
  end
end
