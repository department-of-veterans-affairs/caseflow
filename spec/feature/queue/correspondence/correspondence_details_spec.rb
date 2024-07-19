# frozen_string_literal: true

RSpec.feature("The Correspondence Details page") do
  include CorrespondenceHelpers
  include CorrespondenceTaskHelpers

  let(:current_user) { create(:user) }
  let!(:veteran) { create(:veteran, first_name: "John", last_name: "Testingman", file_number: "8675309") }
  let!(:correspondence) { create(:correspondence, veteran: veteran) }

  context "correspondence details" do
    before :each do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user, roles: ["Inbound Ops Team"])
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "properly loads the details page" do
      visit "/queue/correspondence/#{correspondence.uuid}"

      # Veteran Details
      expect(page).to have_content("8675309")
      expect(page).to have_content("John Testingman")

      # View all correspondence link
      expect(page).to have_link("View all correspondence")

      # Record status
      expect(page).to have_content("Record status: Pending")

      # Tabs
      expect(page).to have_content("Correspondence and Appeal Tasks")
      expect(page).to have_content("Package Details")
      expect(page).to have_content("Response Letters")
      expect(page).to have_content("Associated Prior Mail")
    end
  end

  context "correspondence details as standard caseflow user" do
    before :each do
      Bva.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "properly loads the details page for other caseflow users" do
      visit "/queue/correspondence/#{correspondence.uuid}"

      # Verify the user can see the correspondence details page
      expect(page).to_not have_content("Drat!")
    end

    it "does not load other correspondence pages for other caseflow users" do
      visit "/queue/correspondence"

      # Verify the user is routed to /unauthorized
      expect(page).to have_content("Drat!")
    end
  end

  context "correspondence in the Completed tab of Your Correspondence Queue" do
    let(:current_user) { create(:user) }
    before :each do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user, roles: ["Inbound Ops Team"])
      FeatureToggle.enable!(:correspondence_queue)
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      @correspondences = Array.new(20) do
        review_correspondence = create(:correspondence)
        rpt = ReviewPackageTask.find_by(appeal_id: review_correspondence.id)
        rpt.update!(assigned_to: current_user, status: "completed")
        rpt.save!
        review_correspondence
      end
    end

    it "Verify that the user is taken to the Details page of the correspondence by clicking on correspondence" do
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Completed correspondence")
      find_all("#task-link").first.click
      visit "/queue/correspondence/#{@correspondences.first.uuid}"
      expect(page).to have_content(@correspondences.first.veteran.file_number)
    end
  end

  context "correspondence in the Completed tab of Correspondence Cases" do
    let(:current_user) { create(:inbound_ops_team_supervisor) }
    before :each do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user, roles: ["Inbound Ops Team"])
      FeatureToggle.enable!(:correspondence_queue)
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      @correspondences = Array.new(20) do
        review_correspondence = create(:correspondence)
        rpt = ReviewPackageTask.find_by(appeal_id: review_correspondence.id)
        rpt.update!(assigned_to: current_user, status: "completed")
        rpt.save!
        review_correspondence
      end
    end

    it "Verify that the user is taken to the Details page of the correspondence by clicking on correspondence" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Completed correspondence")
      find_all("#task-link").first.click
      visit "/queue/correspondence/#{@correspondences.first.uuid}"
      expect(page).to have_content(@correspondences.first.veteran.file_number)
    end
  end
end
