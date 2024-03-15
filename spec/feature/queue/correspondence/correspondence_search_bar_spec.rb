# frozen_string_literal: true

RSpec.feature("Search Bar for Correspondence") do
  include CorrespondenceTaskHelpers
  # alias this to avoid the method name collision
  alias_method :create_efolderupload_task, :create_efolderupload_failed_task

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
      expect(page).to have_current_path("/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc")
    end
  end

  context "correspondence assigned tab - locate the search bar" do
    let(:current_user) { create(:user) }
    before :each do
      MailTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    before do
      10.times do
        review_correspondence = create(:correspondence)
        rpt = ReviewPackageTask.find_by(appeal_id: review_correspondence.id)
        rpt.update!(assigned_to: current_user, status: "assigned")
        rpt.save!
      end
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "successfully opens the assigned tab, finds the search box, and enters data there." do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      expect(page).to have_content("Filter table by any of its columns")
      veteran = Veteran.first
      find_by_id("searchBar").fill_in with: veteran.last_name
      search_value = find("tbody > tr:nth-child(1) > td:nth-child(1)").text
      expect(search_value.include?(veteran.last_name))
    end

    it "should display the search bar with text even we shift to other tabs " do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      expect(page).to have_content("Filter table by any of its columns")
      veteran = Veteran.first
      find_by_id("searchBar").fill_in with: veteran.last_name
      find_by_id("tasks-tabwindow-tab-1").click
      expect(find_by_id("searchBar").value).to eq veteran.last_name
    end
  end
end
