# frozen_string_literal: true

RSpec.feature("The Correspondence Details page") do
  include CorrespondenceHelpers
  include CorrespondenceTaskHelpers

  let(:current_user) { create(:user) }
  let(:current_super) { create(:inbound_ops_team_supervisor) }
  let!(:veteran) { create(:veteran, first_name: "John", last_name: "Testingman", file_number: "8675309") }
  let!(:correspondence) { create(:correspondence, :pending, veteran: veteran) }

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
      expect(page).to have_content("View all correspondence")

      # Record status
      expect(page).to have_content("Record status:")

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

  context "correspondence record status matches correspondence root task status and user access" do
    let!(:completed_correspondence) { create(:correspondence, :completed) }
    let!(:pending_correspondence) { create(:correspondence, :pending) }
    let!(:unassigned_correspondence) { create(:correspondence, :unassigned) }

    before do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user, roles: ["Inbound Ops Team"])
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "checks default match of pending" do
      visit "/queue/correspondence/#{pending_correspondence.uuid}"
      expect(page).to have_content("Record status: Pending")
    end

    it "checks that status has been updated to completed" do
      visit "/queue/correspondence/#{completed_correspondence.uuid}"
      # Record status - Completed
      expect(page).to have_content("Record status: Completed")
    end
  end

  context "checks correspondence details page access and user rerouting - user" do
    let!(:pending_correspondence) { create(:correspondence, :pending) }
    let!(:unassigned_correspondence) { create(:correspondence, :unassigned) }

    before do
      correspondence_spec_user_access
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "checks that pending status correspondences will load" do
      visit "/queue/correspondence/#{pending_correspondence.uuid}"
      expect(page).to have_content("Record status: Pending")
      expect(page).to have_content(pending_correspondence.veteran_full_name)
    end

    it "checks that unassigned status correspondences will be rerouted" do
      visit "/queue/correspondence/#{unassigned_correspondence.uuid}"
      expect(page).to have_content("Your Correspondence")
    end
  end

  context "checks correspondence details page access and user rerouting - super" do
    let!(:completed_correspondence) { create(:correspondence, :completed) }
    let!(:action_correspondence) { create(:correspondence, :action_required) }

    before do
      correspondence_spec_super_access
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "checks that completed status correspondences will load" do
      visit "/queue/correspondence/#{completed_correspondence.uuid}"
      expect(page).to have_content("Record status: Completed")
      expect(page).to have_content(completed_correspondence.veteran_full_name)
    end

    it "checks that unassigned status correspondences will be rerouted" do
      visit "/queue/correspondence/#{action_correspondence.uuid}"
      expect(page).to have_content("Correspondence Cases")
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

  context "correspondence package details tab" do
    before do
      correspondence_spec_user_access
      FeatureToggle.enable!(:correspondence_queue)
      @correspondence = create(
        :correspondence,
        :pending,
        veteran: veteran,
        va_date_of_receipt: "Tue, 23 Jul 2024 00:00:00 EDT -04:00",
        nod: false,
        notes: "Note Test"
      )
    end

    it "checks the General Information of Veteran" do
      visit "/queue/correspondence/#{@correspondence.uuid}"
      safe_click "#tasks-tabwindow-tab-1"
      expect(page).to have_content("John Testingman (8675309)")
      expect(page).to have_content("a correspondence type.")
      expect(page).to have_content("Non-NOD")
      expect(page).to have_content("07/23/2024")
      expect(page).to have_content("Note Test")
    end
  end

  context "testing for other motion dropdowns" do
    before do
      correspondence_spec_user_access
      FeatureToggle.enable!(:correspondence_queue)
      @correspondence = create(
        :correspondence,
        :pending,
        veteran: veteran,
        va_date_of_receipt: "Wed, 24 Jul 2024 00:00:00 EDT -04:00",
        nod: false,
        notes: "Notes for Other Motion"
      )
    end

    before :each do
      OtherMotionCorrespondenceTask.create!(
        parent: @correspondence.tasks[0],
        appeal: @correspondence,
        appeal_type: "Correspondence",
        assigned_to_type: "User",
        assigned_to: current_user,
        instructions: ["Other Motion"],
        assigned_at: Time.current
      )
      @correspondence.open_intake_task.update!(status: Constants.TASK_STATUSES.completed)
    end

    it "checks that Other motion task can be cancelled." do
      visit "/queue/correspondence/#{@correspondence.uuid}"
      click_dropdown(prompt: "Select an action", text: "Cancel task")
      find(".cf-form-textarea", match: :first).fill_in with: "Cancel task test"
      click_button "Cancel-task-button-id-1"
      expect(page).to have_content("Other motion task has been cancelled.")
    end

    it "checks that Other Motion task can be completed." do
      visit "/queue/correspondence/#{@correspondence.uuid}"
      click_dropdown(prompt: "Select an action", text: "Mark task complete")
      find(".cf-form-textarea", match: :first).fill_in with: "Complete task test"
      click_button "Mark-as-complete-button-id-1"
      expect(page).to have_content("Other motion task has been marked complete.")
    end
  end
end