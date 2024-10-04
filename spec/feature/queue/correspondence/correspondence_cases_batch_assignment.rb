# frozen_string_literal: true

RSpec.feature("The Correspondence Cases page") do
  include CorrespondenceTaskHelpers
  # alias this to avoid the method name collision
  alias_method :create_efolderupload_task, :create_efolderupload_failed_task
  context "correspondence batch assignment cases for assigned and unassigned tabs" do
    let(:current_user) { create(:user) }
    let(:supervisor_user) { create(:inbound_ops_team_supervisor) }
    before :each do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: supervisor_user)
    end
    let(:organization) { InboundOpsTeam.singleton }
    let(:mail_user) { User.authenticate!(roles: ["Mail Team"]) }
    let(:target_user) { create(:user, css_id: "TARGET_USER") }
    let(:nod_user) { create(:user, css_id: "NOD_USER") }

    let(:wait_time) { 30 }

    before do
      organization.add_user(mail_user)
      mail_user.reload
    end

    before do
      organization.add_user(target_user)
      organization.add_user(nod_user)
      target_user.reload
      nod_user.reload
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      5.times do
        corres_array = (1..4).map { create(:correspondence) }
        task_array = [ReassignPackageTask, RemovePackageTask, SplitPackageTask, MergePackageTask]

        corres_array.each_with_index do |corres, index|
          rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
          task_array[index].create!(
            parent_id: rpt.id,
            appeal_id: corres.id,
            appeal_type: "Correspondence",
            assigned_to: InboundOpsTeam.singleton,
            assigned_by_id: rpt.assigned_to_id
          )
        end
      end

      # Used to mock a single task to compare task sorting
      ReassignPackageTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10)
      )
      ReassignPackageTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2050, 10, 10)
      )
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "successfully loads the unassigned tab" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      expect(page).to have_content("Correspondence owned by the Mail team are unassigned to an individual:")
      expect(page).to have_content("Assign to Inbound Ops Team user")
      expect(page).to have_button("Assign", disabled: true)
      expect(page).to have_button("Auto assign correspondence")
    end

    it "Verify the inbound ops team user batch assignment with Assign button" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      expect(page).to have_content("Assign to Inbound Ops Team user")
      expect(page).to have_button("Assign", disabled: true)
      expect(page).to have_selector(".cf-select__input")
      all(".cf-select__input").first.click
      find_by_id("react-select-2-option-1").click
      page.execute_script('
        document.querySelectorAll(".cf-form-checkbox input[type=\'checkbox\']").forEach((checkbox, index) => {
          if (index < 3) {
            checkbox.click();
          }
        });
      ')
      expect(page).to have_button("Assign", disabled: false)
      find_by_id("button-Assign").click
      expect(page).to have_content("You have successfully assigned 3 Correspondences to #{mail_user.css_id}.")
      expect(page).to have_content("Please go to your individual queue to see any self-assigned correspondences.")
    end

    it "verifies failure when assigning a correspondence to an inbound ops team user when queue limit is reached" do
      60.times do
        corr = create(:correspondence)
        rpt = ReviewPackageTask.find_by(appeal_id: corr.id)
        rpt.update!(status: Constants.TASK_STATUSES.in_progress, assigned_to: target_user)
      end

      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      expect(page).to have_content("Assign to Inbound Ops Team user")
      expect(page).to have_button("Assign", disabled: true)
      expect(page).to have_selector(".cf-select__input")
      all(".cf-select__input").first.click
      find_by_id("react-select-2-option-2").click
      page.execute_script('
        document.querySelectorAll(".cf-form-checkbox input[type=\'checkbox\']").forEach((checkbox, index) => {
          if (index < 1) {
            checkbox.click();
          }
        });
      ')
      expect(page).to have_button("Assign", disabled: false)
      find_by_id("button-Assign").click
      expect(page).to have_content("Correspondence was not assigned to #{target_user.css_id}")
      expect(page).to have_content(
        "Case was not assigned to user because maximum capacity has been reached for user's queue."
      )
    end

    it "successfully loads the assigned tab" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      expect(page).to have_content("Correspondence that is currently assigned to mail team users:")
      expect(page).to have_content("Assign to Inbound Ops Team user")
      expect(page).to have_button("Reassign", disabled: true)
    end

    it "Verify the inbound ops team user batch reassignment with Reassign button" do
      40.times do
        correspondence = create(:correspondence)
        parent_task = create_correspondence_intake(correspondence, mail_user)
        create_efolderupload_task(correspondence, parent_task)
      end
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      expect(page).to have_content("Assign to Inbound Ops Team user")
      expect(page).to have_button("Reassign", disabled: true)
      expect(page).to have_selector(".cf-select__input")
      all(".cf-select__input").first.click
      find_by_id("react-select-2-option-1").click
      page.execute_script('
        document.querySelectorAll(".cf-form-checkbox input[type=\'checkbox\']").forEach((checkbox, index) => {
          if (index < 1) {
            checkbox.click();
          }
        });
      ')
      expect(page).to have_button("Reassign", disabled: false)
      find_by_id("button-Reassign").click
      expect(page).to have_content("You have successfully reassigned 1 Correspondence to #{mail_user.css_id}.")
      expect(page).to have_content("Please go to your individual queue to see any self-assigned correspondence.")
    end

    it "verifies failure when reassigning a correspondence to an inbound ops team user when queue limit is reached" do
      60.times do
        corr = create(:correspondence)
        rpt = ReviewPackageTask.find_by(appeal_id: corr.id)
        rpt.update!(status: Constants.TASK_STATUSES.in_progress, assigned_to: target_user)
      end

      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      expect(page).to have_content("Assign to Inbound Ops Team user")
      expect(page).to have_button("Reassign", disabled: true)
      expect(page).to have_selector(".cf-select__input")
      all(".cf-select__input").first.click
      find_by_id("react-select-2-option-2").click
      page.execute_script('
        document.querySelectorAll(".cf-form-checkbox input[type=\'checkbox\']").forEach((checkbox, index) => {
          if (index < 1) {
            checkbox.click();
          }
        });
      ')
      expect(page).to have_button("Reassign", disabled: false)
      find_by_id("button-Reassign").click
      expect(page).to have_content("Correspondence was not reassigned to #{target_user.css_id}")
      expect(page).to have_content(
        "Case was not reassigned to user because maximum capacity has been reached for user's queue."
      )
    end

    it "verifies failure when reassigning a correspondence to an inbound ops team user that lacks NOD permissions" do
      40.times do
        correspondence = create(:correspondence, :nod)
        auto = AutoAssignableUserFinder.new(nod_user)
        parent_task = create_correspondence_intake(correspondence, nod_user)
        create_efolderupload_task(correspondence, parent_task)
        auto.can_user_work_this_correspondence?(user: nod_user, correspondence: correspondence)
      end

      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      expect(page).to have_content("Assign to Inbound Ops Team user")
      expect(page).to have_button("Reassign", disabled: true)
      expect(page).to have_selector(".cf-select__input")
      all(".cf-select__input").first.click
      find_by_id("react-select-2-option-3").click
      page.execute_script('
        document.querySelectorAll(".cf-form-checkbox input[type=\'checkbox\']").forEach((checkbox, index) => {
          if (index < 1) {
            checkbox.click();
          }
        });
      ')
      expect(page).to have_button("Reassign", disabled: false)
      find_by_id("button-Reassign").click
      expect(page).to have_content("Correspondence was not reassigned to #{nod_user.css_id}")
      expect(page).to have_content("Case was not reassigned to user because of NOD permissions settings.")
    end

    it "Verify the inbound ops team user multiple batch reassignment with NOD permissions" do
      40.times do
        correspondence = create(:correspondence, :nod)
        auto = AutoAssignableUserFinder.new(nod_user)
        parent_task = create_correspondence_intake(correspondence, nod_user)
        create_efolderupload_task(correspondence, parent_task)
        auto.can_user_work_this_correspondence?(user: nod_user, correspondence: correspondence)
      end

      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      expect(page).to have_content("Assign to Inbound Ops Team user")
      expect(page).to have_button("Reassign", disabled: true)
      expect(page).to have_selector(".cf-select__input")
      all(".cf-select__input").first.click
      find_by_id("react-select-2-option-3").click
      page.execute_script('
        document.querySelectorAll(".cf-form-checkbox input[type=\'checkbox\']").forEach((checkbox, index) => {
          if (index < 3) {
            checkbox.click();
          }
        });
      ')
      expect(page).to have_button("Reassign", disabled: false)
      find_by_id("button-Reassign").click
      expect(page).to have_content("Not all correspondence was reassigned to #{nod_user.css_id}")
      expect(page).to have_content("3 cases were not reassigned to user because of NOD permissions settings.")
    end

    it "Verify the inbound ops team user multiple batch reassignment with reassign button with queue limit" do
      60.times do
        corr = create(:correspondence)
        rpt = ReviewPackageTask.find_by(appeal_id: corr.id)
        rpt.update!(status: Constants.TASK_STATUSES.in_progress, assigned_to: target_user)
      end

      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      expect(page).to have_content("Assign to Inbound Ops Team user")
      expect(page).to have_button("Reassign", disabled: true)
      expect(page).to have_selector(".cf-select__input")
      all(".cf-select__input").first.click
      find_by_id("react-select-2-option-2").click
      page.execute_script('
        document.querySelectorAll(".cf-form-checkbox input[type=\'checkbox\']").forEach((checkbox, index) => {
          if (index < 3) {
            checkbox.click();
          }
        });
      ')
      expect(page).to have_button("Reassign", disabled: false)
      find_by_id("button-Reassign").click
      expect(page).to have_content("Not all correspondence was reassigned to #{target_user.css_id}")
      expect(page).to have_content(
        "3 cases were not reassigned to user because maximum capacity has been reached for user's queue."
      )
    end
  end
end
