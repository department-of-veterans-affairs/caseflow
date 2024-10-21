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

  context "Correspondence Details - Existing Appeals section" do
    before do
      correspondence_spec_user_access
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "checks the Existing Appeal section" do
      visit "/queue/correspondence/#{correspondence.uuid}"
      expect(page).to have_button("+", class: "cf-submit cf-btn-link usa-button")
      buttons = all("button.cf-submit.cf-btn-link.usa-button", text: "+")
      buttons.first.click
      expect(page).to have_button("_", class: "cf-submit cf-btn-link usa-button")
    end
  end

  context "correspondence package details tab" do
    before do
      correspondence_spec_super_access
      FeatureToggle.enable!(:correspondence_queue)
      @correspondence = create(
        :correspondence,
        :pending,
        veteran: veteran,
        va_date_of_receipt: "Tue, 23 Jul 2024 00:00:00 EDT -04:00",
        nod: false,
        notes: "Note Test"
      )
      CorrespondenceType.create!(
        name: "General Information Test Correspondence Type"
      )
    end

    it "checks the General Information of Veteran and allows edits to it" do
      visit "/queue/correspondence/#{@correspondence.uuid}"
      safe_click "#tasks-tabwindow-tab-1"
      expect(page).to have_content("John Testingman (8675309)")
      expect(page).to have_content("a correspondence type.")
      expect(page).to have_content("Non-NOD")
      expect(page).to have_content("07/23/2024")
      expect(page).to have_content("Note Test")

      # Edit information and check
      safe_click "#tasks-tabwindow-tab-1"
      click_button("Edit")
      all("div.input-container > input")[0].fill_in(with: "08/23/2024")
      click_dropdown(text: "General Information Test Correspondence Type")
      find("textarea").fill_in(with: "Note Test Changed")
      click_button("Save")
      expect(page).to have_content("8/23/2024")
      expect(page).to have_content("General Information Test Correspondence Type")
      expect(page).to have_content("Note Test Changed")
    end
  end

  context "correspondence details Prior Mail tab" do
    let(:current_user) { create(:inbound_ops_team_supervisor) }
    let(:correspondences) do
      (0..1).map do |i|
        create(
          :correspondence,
          :related_correspondence,
          :pending,
          veteran: veteran,
          va_date_of_receipt: i == 0 ? "Tue, 23 Jul 2024 00:00:00 EDT -04:00" : "Wed, 24 Jul 2024 00:00:00 EDT -04:00",
          nod: false,
          notes: i == 0 ? "Note Test" : "Related Correspondence Test"
        )
      end
    end
    let(:correspondence) { correspondences[0] }
    let(:related_correspondence) { correspondences[1] }

    before :each do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user, roles: ["Inbound Ops Team"])
      correspondence_spec_user_access
      FeatureToggle.enable!(:correspondence_queue)

      # Create the relation between correspondence and related_correspondence
      CorrespondenceRelation.create!(
        correspondence_id: correspondence.id,
        related_correspondence_id: related_correspondence.id
      )
    end

    it "properly removes prior mail relationship from corespondence" do
      visit "/queue/correspondence/#{correspondence.uuid}"
      click_on "Associated Prior Mail"
      page.execute_script('
      document.querySelectorAll(".cf-form-checkbox input[type=\'checkbox\']").forEach((checkbox, index) => {
        if (index < 6) {
          checkbox.click();
        }
      });
      ')
      click_button("Save changes")
      visit current_path
      click_on "Associated Prior Mail"

      # Confirm that all checkboxes are unchecked after the page refresh
      page.execute_script('
        document.querySelectorAll(".cf-form-checkbox input[type=\'checkbox\']").forEach((checkbox) => {
          if (checkbox.checked) {
            throw new Error("Checkbox should be unchecked, but it is checked.");
          }
        });
      ')
    end
  end
end

