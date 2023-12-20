# frozen_string_literal: true

RSpec.feature "Bulk task assignment", :postgres do
  let(:org) { HearingsManagement.singleton }
  let(:user) { create(:user) }

  before do
    OrganizationsUser.make_user_admin(user, org)
    User.authenticate!(user: user)
  end

  describe "bulk assign hearing tasks" do
    def fill_in_and_submit_bulk_assign_modal
      options = find_all("option")
      assign_to = options.find { |option| option.text =~ /#{user.full_name}/ }
      assign_to.click
      task_type = options.find { |option| option.text =~ /No Show Hearing Task/ }
      task_type.click
      number_of_tasks = options.find { |option| option.text =~ /3 \(all available tasks\)/ }
      number_of_tasks.click
      expect(page).to_not have_content("Please select a value")
      submit = find("button", id: "Bulk-Assign-Tasks-button-id-1")
      submit.click
    end

    it "is able to bulk assign tasks for the hearing management org" do
      3.times do
        create(:no_show_hearing_task)
      end
      visit("/organizations/hearings-management")
      click_button(text: "Assign Tasks")
      expect(page).to have_content("Bulk Assign Tasks")

      # When missing required fields
      submit = find("button", id: "Bulk-Assign-Tasks-button-id-1")
      submit.click
      expect(page).to have_content("Please select a value")
      expect(page).to_not have_content("Loading")

      fill_in_and_submit_bulk_assign_modal
      expect(page).to have_content("Assigned (3)")
      expect(NoShowHearingTask.where(assigned_to: user).size).to eq 3
    end

    it "filters regional office by task types" do
      # RO17 == St. Petersburg
      # RO19 == Columbia
      2.times do
        create(
          :no_show_hearing_task,
          appeal: create(:appeal, closest_regional_office: "RO17")
        )
      end

      2.times do
        create(
          :evidence_submission_window_task,
          appeal: create(:appeal, closest_regional_office: "RO19"),
          assigned_to: HearingsManagement.singleton
        )
      end
      visit("/organizations/hearings-management")
      click_button(text: "Assign Tasks")
      expect(page).to have_content("Bulk Assign Tasks")
      options = find_all("option")
      task_type = options.find { |option| option.text =~ /No Show/ }
      task_type.click
      options = find_all("option")
      expect(options.map(&:text).include?("Columbia")).to eq false

      task_type = options.find { |option| option.text =~ /Evidence/ }
      task_type.click
      options = find_all("option")
      expect(options.map(&:text).include?("St. Petersburg")).to eq false
    end

    it "filters tasks by regional office and task type" do
      4.times do
        create(
          :no_show_hearing_task,
          appeal: create(:appeal, closest_regional_office: "RO17")
        )
      end

      2.times do
        create(
          :evidence_submission_window_task,
          appeal: create(:appeal, closest_regional_office: "RO19"),
          assigned_to: HearingsManagement.singleton
        )
      end

      5.times do
        create(
          :evidence_submission_window_task,
          appeal: create(:appeal, closest_regional_office: "RO17"),
          assigned_to: HearingsManagement.singleton
        )
      end

      visit("/organizations/hearings-management")
      click_button(text: "Assign Tasks")
      expect(page).to have_content("Bulk Assign Tasks")
      options = find_all("option")
      regional_office = options.find { |option| option.text =~ /St. Petersburg/ }
      regional_office.click
      task_type = options.find { |option| option.text =~ /No Show/ }
      task_type.click

      values = find_all("option").map(&:text)
      expect(values.include?("4 (all available tasks)")).to eq true
    end

    it "filters task types by regional office" do
      2.times do
        create(
          :no_show_hearing_task,
          appeal: create(:appeal, closest_regional_office: "RO17")
        )
      end

      2.times do
        create(
          :evidence_submission_window_task,
          appeal: create(:appeal, closest_regional_office: "RO19"),
          assigned_to: HearingsManagement.singleton
        )
      end
      visit("/organizations/hearings-management")
      click_button(text: "Assign Tasks")
      expect(page).to have_content("Bulk Assign Tasks")
      options = find_all("option")
      regional_office = options.find { |option| option.text =~ /Columbia/ }
      regional_office.click
      values = find_all("option").map(&:value)
      expect(values.include?("NoShowHearingTask")).to eq false
      expect(values.include?("EvidenceSubmissionWindowTask")).to eq true
    end
  end

  context "when there are more tasks than will fit on a single page for any org" do
    let(:org) { create(:organization) }
    let(:task_count) { TaskPager::TASKS_PER_PAGE + 2 }
    let(:regional_offices) do
      RegionalOffice
        .ros_with_hearings
        .keys
        .reject { |ro_key| ro_key == HearingDay::REQUEST_TYPES[:virtual] }
        .map { |ro_key| RegionalOffice.find!(ro_key) }
        .last(task_count)
    end

    before do
      regional_offices.each do |ro|
        appeal = create(:appeal, :hearing_docket, closest_regional_office: ro.key)
        create(:no_show_hearing_task, appeal: appeal, assigned_to: org)
      end
    end

    it "correctly populates modal dropdowns with all options" do
      visit(org.path)

      expect(page).to have_content(COPY::BULK_ASSIGN_BUTTON_TEXT)
      click_button(text: COPY::BULK_ASSIGN_BUTTON_TEXT)
      expect(page).to have_content(COPY::BULK_ASSIGN_MODAL_TITLE)

      options = find("select[id='Regional office']").find_all("option")

      # Skip the first two since they are 1) "Select" and 2) an empty option to reset the dropdown.
      expect(options.count).to eq(task_count + 2)
      regional_office_options = options.last(task_count).map(&:text)

      # Sort the regional offices we expect to see by city name.
      sorted_regional_offices = regional_offices.map(&:city).sort
      expect(regional_office_options).to eq(sorted_regional_offices)
    end
  end

  context "when the user is not an admin" do
    before do
      user = create(:user)
      org.add_user(user)
      User.authenticate!(user: user)
    end

    it "does not show the bulk assign button" do
      visit(org.path)

      expect(page).to have_content(org.name)
      expect(page).to have_no_content(COPY::BULK_ASSIGN_BUTTON_TEXT)
    end
  end
end
