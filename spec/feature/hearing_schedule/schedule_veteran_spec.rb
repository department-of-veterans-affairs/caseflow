require "rails_helper"

RSpec.feature "Schedule Veteran For A Hearing" do
  let!(:hearings_user) do
    create(:hearings_management)
  end

  let!(:current_user) do
    User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"])
  end

  let(:other_user) { create(:user) }

  before do
    OrganizationsUser.add_user_to_organization(current_user, HearingsManagement.singleton)
    OrganizationsUser.add_user_to_organization(other_user, HearingsManagement.singleton)
  end

  context "When creating Caseflow Central hearings" do
    let!(:hearing_day) { create(:hearing_day) }
    let!(:vacols_case) do
      create(
        :case, :central_office_hearing,
        bfcorlid: "123454787S"
      )
    end

    let!(:veteran) { create(:veteran, file_number: "123454787") }

    scenario "Schedule Veteran for central hearing",
             skip: "This test passes on local but fails intermittently on circle" do
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(index: 7)
      click_button("Legacy Veterans Waiting")
      appeal_link = page.find(:xpath, "//tbody/tr/td[1]/a")
      appeal_link.click
      expect(page).not_to have_content("loading to VACOLS.", wait: 30)
      expect(page).to have_content("Currently active tasks", wait: 30)
      click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
      expect(page).to have_content("Time")
      click_dropdown(name: "veteranHearingLocation", text: "Holdrege, NE (VHA) 0 miles away")
      radio_link = find(".cf-form-radio-option", match: :first)
      radio_link.click
      click_button("Schedule")
      find_link("Back to Schedule Veterans").click
      expect(page).to have_content("Schedule Veterans")
      click_button("Scheduled Veterans")
      expect(VACOLS::Case.where(bfcorlid: "123454787S"))
      click_button("Legacy Veterans Waiting")
      expect(page).not_to have_content("123454787S")
      expect(page).to have_content("There are no schedulable veterans")
      expect(VACOLS::CaseHearing.first.folder_nr).to eq vacols_case.bfkey
    end
  end

  context "when video_hearing_requested" do
    let!(:hearing_day) do
      create(
        :hearing_day,
        request_type: HearingDay::REQUEST_TYPES[:video],
        scheduled_for: Time.zone.today + 160,
        regional_office: "RO39"
      )
    end
    let!(:staff) { create(:staff, stafkey: "RO39", stc2: 2, stc3: 3, stc4: 4) }
    let!(:vacols_case) do
      create(
        :case, :video_hearing_requested,
        folder: create(:folder, tinum: "docket-number"),
        bfcorlid: "123456789S",
        bfregoff: "RO39"
      )
    end

    let!(:veteran) { create(:veteran, file_number: "123456789") }

    scenario "Schedule Veteran for video",
             skip: "This test passes on local but fails intermittently on circle" do
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(index: 12)
      click_button("Legacy Veterans Waiting")
      appeal_link = page.find(:xpath, "//tbody/tr/td[1]/a")
      appeal_link.click
      expect(page).not_to have_content("loading to VACOLS.", wait: 30)
      expect(page).to have_content("Currently active tasks", wait: 30)
      click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
      expect(page).to have_content("Time")
      radio_link = find(".cf-form-radio-option", match: :first)
      radio_link.click
      expect(page).not_to have_content("Could not find hearing locations for this veteran", wait: 30)
      click_button("Schedule")
      find_link("Back to Schedule Veterans").click
      expect(page).to have_content("Schedule Veterans")
      click_button("Scheduled Veterans")
      expect(VACOLS::Case.where(bfcorlid: "123456789S"))
      click_button("Legacy Veterans Waiting")
      expect(page).not_to have_content("123456789S")
      expect(page).to have_content("There are no schedulable veterans")
      expect(VACOLS::CaseHearing.first.folder_nr).to eq vacols_case.bfkey
    end
  end

  context "when scheduling an AMA hearing" do
    before do
      FeatureToggle.enable!(:ama_auto_case_distribution)
    end

    after do
      FeatureToggle.disable!(:ama_auto_case_distribution)
    end

    let!(:hearing_day) do
      create(
        :hearing_day,
        request_type: HearingDay::REQUEST_TYPES[:video],
        scheduled_for: Time.zone.today + 160,
        regional_office: "RO39"
      )
    end
    let!(:staff) { create(:staff, stafkey: "RO39", stc2: 2, stc3: 3, stc4: 4) }
    let!(:appeal) do
      create(
        :appeal,
        :with_tasks,
        docket_type: "hearing",
        veteran: create(:veteran, closest_regional_office: "RO39")
      )
    end

    scenario "Can create multiple admin actions and reassign them" do
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(text: "Denver")
      click_button("AMA Veterans Waiting")
      click_on "Bob Smith"

      # Case details screen
      click_dropdown(text: Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h[:label])

      # Admin action screen

      # First admin action
      expect(page).to have_content("Submit admin action")
      click_dropdown(text: HearingAdminActionIncarceratedVeteranTask.label)
      fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "Action 1"

      # Second admin action
      click_on COPY::ADD_COLOCATED_TASK_ANOTHER_BUTTON_LABEL
      within all('div[id^="action_"]', count: 2)[1] do
        click_dropdown(text: HearingAdminActionContestedClaimantTask.label)
        fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "Action 2"
      end

      click_on "Assign Action"
      expect(page).to have_content("You have assigned 2 administrative actions")

      within all("div", class: "Select", count: 2).first do
        click_dropdown(text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h[:label])
      end

      click_on "Submit"

      # Your queue
      visit "/queue"
      click_on "Bob Smith"

      # Reassign
      within find("tr", text: "BVATWARNER") do
        click_dropdown(text: Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h[:label])
      end

      click_dropdown(text: other_user.full_name)
      fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "Reassign"
      click_on "Submit"

      # Case should exist in other users' queue
      User.authenticate!(user: other_user)
      visit "/queue"

      expect(page).to have_content("Bob Smith")
    end

    scenario "Schedule Veteran for a video hearing with admin actions that can be put on hold and completed" do
      # Do the first part of the test in the past so we can wait for our hold to complete.
      Timecop.travel(20.days.ago) do
        visit "hearings/schedule/assign"
        expect(page).to have_content("Regional Office")
        click_dropdown(text: "Denver")
        click_button("AMA Veterans Waiting")
        click_on "Bob Smith"

        # Case details screen
        click_dropdown(text: Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h[:label])

        # Admin action screen

        # First admin action
        expect(page).to have_content("Submit admin action")
        click_dropdown(text: HearingAdminActionIncarceratedVeteranTask.label)
        fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "Action 1"

        # Second admin action
        # click_on COPY::ADD_COLOCATED_TASK_ANOTHER_BUTTON_LABEL
        # within all('div[id^="action_"]', count: 2)[1] do
        #   click_dropdown(text: HearingAdminActionContestedClaimantTask.label)
        #   fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "Action 2"
        # end

        click_on "Assign Action"
        expect(page).to have_content("You have assigned an administrative action")

        click_dropdown(text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h[:label])
        click_on "Submit"

        # Your queue
        visit "/queue"
        click_on "Bob Smith"
        click_dropdown(text: Constants.TASK_ACTIONS.PLACE_HOLD.to_h[:label])

        # On hold
        click_dropdown(text: "15 days")
        fill_in "Notes:", with: "Waiting for response"

        click_on "Place case on hold"

        expect(page).to have_content("case has been placed on hold")
      end

      # Refresh the page in the present, and the hold should be completed.
      visit "/queue"
      click_on "Bob Smith"

      # Complete the admin action
      click_dropdown(text: Constants.TASK_ACTIONS.MARK_COMPLETE.to_h[:label])
      click_on "Mark complete"

      expect(page).to have_content("has been marked complete")

      # Schedule veteran!
      find("a", text: "Switch views").click
      click_on "Hearings Management team"

      click_on "Bob Smith"
      click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
      click_dropdown(text: "Denver")

      within find(".dropdown-hearingDate") do
        click_dropdown(index: 1)
      end

      find("label", text: "9:00 am").click

      click_on "Schedule"

      expect(page).to have_content("You have successfully assigned")

      # Ensure the veteran appears on the scheduled page
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(text: "Denver")

      expect(page).to have_content(appeal.docket_number)

      # Ensure the veteran is no longer in the veterans waiting to be scheduled
      click_button("AMA Veterans Waiting")
      expect(page).to have_content("There are no schedulable veterans")
    end

    scenario "Withdraw Veteran's hearing request" do
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(text: "Denver")
      click_button("AMA Veterans Waiting")
      click_on "Bob Smith"

      click_dropdown(text: Constants.TASK_ACTIONS.WITHDRAW_HEARING.to_h[:label])

      click_on "Submit"

      expect(page).to have_content("You have successfully withdrawn")
      expect(appeal.tasks.where(type: ScheduleHearingTask.name).first.status).to eq(Constants.TASK_STATUSES.completed)
      expect(appeal.tasks.where(type: EvidenceSubmissionWindowTask.name).count).to eq(1)

      click_on "Back to Hearing Schedule"
      expect(page).to have_content("Denver")
    end
  end
end
