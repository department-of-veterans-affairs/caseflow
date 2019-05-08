# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Schedule Veteran For A Hearing" do
  let!(:current_user) do
    user = create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"])
    User.authenticate!(user: user)
  end

  let(:other_user) { create(:user) }

  before do
    OrganizationsUser.add_user_to_organization(current_user, HearingsManagement.singleton)
    OrganizationsUser.add_user_to_organization(current_user, HearingAdmin.singleton)
    OrganizationsUser.add_user_to_organization(other_user, HearingsManagement.singleton)
    OrganizationsUser.add_user_to_organization(other_user, HearingAdmin.singleton)
  end

  context "When creating Caseflow Central hearings" do
    let!(:hearing_day) { create(:hearing_day, scheduled_for: Time.zone.today + 30.days) }
    let!(:vacols_case) do
      create(
        :case, :central_office_hearing,
        bfcorlid: "123454787S",
        bfcurloc: "CASEFLOW"
      )
    end
    let!(:legacy_appeal) do
      create(
        :legacy_appeal, vacols_case: vacols_case
      )
    end
    let!(:schedule_hearing_task) do
      create(
        :schedule_hearing_task, appeal: legacy_appeal
      )
    end

    let!(:veteran) { create(:veteran, file_number: "123454787") }
    let!(:hearing_location_dropdown_label) { "Suggested Hearing Location" }

    scenario "Schedule Veteran for central hearing" do
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(text: "Central")
      click_button("Legacy Veterans Waiting")
      appeal_link = page.find(:xpath, "//tbody/tr/td[2]/a")
      appeal_link.click
      expect(page).not_to have_content("loading to VACOLS.", wait: 30)
      expect(page).to have_content("Currently active tasks", wait: 30)
      click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
      expect(page).to have_content("Time")

      # Wait for the contents of the dropdown to finish loading before clicking into the dropdown.
      expect(page).to have_content(hearing_location_dropdown_label)
      click_dropdown(name: "appealHearingLocation", text: "Holdrege, NE (VHA) 0 miles away")
      find("label", text: "9:00 am").click
      click_button("Schedule")
      click_on "Back to Schedule Veterans"
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
        scheduled_for: Time.zone.today + 60.days,
        regional_office: "RO39"
      )
    end
    let!(:staff) { create(:staff, stafkey: "RO39", stc2: 2, stc3: 3, stc4: 4) }
    let!(:vacols_case) do
      create(
        :case, :video_hearing_requested,
        folder: create(:folder, tinum: "docket-number"),
        bfcorlid: "123456789S",
        bfcurloc: "CASEFLOW",
        bfregoff: "RO39"
      )
    end
    let!(:legacy_appeal) do
      create(
        :legacy_appeal,
        vacols_case: vacols_case,
        closest_regional_office: "RO39"
      )
    end
    let!(:schedule_hearing_task) do
      create(
        :schedule_hearing_task, appeal: legacy_appeal
      )
    end
    let!(:veteran) { create(:veteran, file_number: "123456789") }

    scenario "Schedule Veteran for video" do
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(text: "Denver, CO")
      click_button("Legacy Veterans Waiting")
      appeal_link = page.find(:xpath, "//tbody/tr/td[2]/a")
      appeal_link.click
      expect(page).not_to have_content("loading to VACOLS.", wait: 30)
      expect(page).to have_content("Currently active tasks", wait: 30)
      click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
      expect(page).to have_content("Time")
      find("label", text: "8:30 am").click
      expect(page).not_to have_content("Could not find hearing locations for this veteran", wait: 30)
      click_button("Schedule")
      click_on "Back to Schedule Veterans"
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
      FeatureToggle.enable!(:ama_acd_tasks)
    end

    after do
      FeatureToggle.disable!(:ama_acd_tasks)
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
        closest_regional_office: "RO39",
        veteran: create(:veteran)
      )
    end
    let(:incarcerated_veteran_task_instructions) { "Incarcerated veteran task instructions" }
    let(:contested_claimant_task_instructions) { "Contested claimant task instructions" }

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
      fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: incarcerated_veteran_task_instructions

      # Second admin action
      click_on COPY::ADD_COLOCATED_TASK_ANOTHER_BUTTON_LABEL
      within all('div[id^="action_"]', count: 2)[1] do
        click_dropdown(text: HearingAdminActionContestedClaimantTask.label)
        fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: contested_claimant_task_instructions
      end

      click_on "Assign Action"

      # The banner has the correct content
      expect(page).to have_content(
        format(
          COPY::ADD_COLOCATED_TASK_CONFIRMATION_TITLE,
          "2",
          "actions",
          [HearingAdminActionIncarceratedVeteranTask.label, HearingAdminActionContestedClaimantTask.label].join(", ")
        )
      )

      # The timeline has the correct content
      incarcerated_row = find("dd", text: HearingAdminActionIncarceratedVeteranTask.label).find(:xpath, "ancestor::tr")
      incarcerated_row.click_on(
        COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL
      )
      expect(incarcerated_row).to have_content incarcerated_veteran_task_instructions

      contested_row = find("dd", text: HearingAdminActionContestedClaimantTask.label).find(:xpath, "ancestor::tr")
      contested_row.click_on(
        COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL
      )
      expect(contested_row).to have_content contested_claimant_task_instructions

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
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(text: "Denver")
      click_button("AMA Veterans Waiting")

      click_on "Bob Smith"
      click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
      click_dropdown({ text: "Denver" }, find(".dropdown-regionalOffice"))
      click_dropdown({ index: 1 }, find(".dropdown-hearingDate"))

      find("label", text: "8:30 am").click

      click_on "Schedule"

      expect(page).to have_content("You have successfully assigned")

      # Ensure the veteran appears on the scheduled page

      expect(page).to have_content(appeal.docket_number)

      # Ensure the veteran is no longer in the veterans waiting to be scheduled
      click_on "Back to Schedule Veterans"
      expect(page).to have_content("Regional Office")
      click_dropdown(text: "Denver")
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
      expect(appeal.tasks.where(type: ScheduleHearingTask.name).first.status).to eq(Constants.TASK_STATUSES.cancelled)
      expect(appeal.tasks.where(type: EvidenceSubmissionWindowTask.name).count).to eq(1)

      click_on "Back to Hearing Schedule"
      expect(page).to have_content("Denver")
    end
  end

  context "When list of veterans displays in Legacy Veterans Waiting" do
    let!(:hearing_day) { create(:hearing_day, scheduled_for: Time.zone.today + 30) }
    let!(:schedule_hearing_task1) do
      create(
        :schedule_hearing_task, appeal: create(
          :legacy_appeal,
          vacols_case: create(
            :case, :central_office_hearing,
            :type_cavc_remand,
            bfcorlid: "123454787S",
            bfcurloc: "CASEFLOW",
            folder: create(
              :folder,
              ticknum: "91",
              tinum: "1545678",
              titrnum: "123454787S"
            )
          )
        )
      )
    end
    let!(:veteran1) { create(:veteran, file_number: "123454787") }
    let!(:schedule_hearing_task2) do
      create(
        :schedule_hearing_task, appeal: create(
          :legacy_appeal,
          vacols_case: create(
            :case,
            :central_office_hearing,
            :aod,
            :type_original,
            bfcorlid: "123454788S",
            bfcurloc: "CASEFLOW",
            folder: create(
              :folder,
              ticknum: "92",
              tinum: "1645621",
              titrnum: "123454788S"
            )
          )
        )
      )
    end
    let!(:veteran2) { create(:veteran, file_number: "123454788") }
    let!(:schedule_hearing_task3) do
      create(
        :schedule_hearing_task, appeal: create(
          :legacy_appeal,
          vacols_case: create(
            :case,
            :central_office_hearing,
            :aod,
            :type_original,
            bfcorlid: "323454787S",
            bfcurloc: "CASEFLOW",
            folder: create(
              :folder,
              ticknum: "93",
              tinum: "1645678",
              titrnum: "323454787S"
            )
          )
        )
      )
    end
    let!(:veteran3) { create(:veteran, file_number: "323454787") }
    let!(:schedule_hearing_task4) do
      create(
        :schedule_hearing_task, appeal: create(
          :legacy_appeal,
          vacols_case: create(
            :case,
            :central_office_hearing,
            :type_original,
            bfcorlid: "123454789S",
            bfcurloc: "CASEFLOW",
            folder: create(
              :folder,
              ticknum: "94",
              tinum: "1445678",
              titrnum: "123454789S"
            )
          )
        )
      )
    end
    let!(:veteran4) { create(:veteran, file_number: "123454789") }
    let!(:schedule_hearing_task5) do
      create(
        :schedule_hearing_task, appeal: create(
          :legacy_appeal,
          vacols_case: create(
            :case,
            :central_office_hearing,
            :type_original,
            bfcorlid: "523454787S",
            bfcurloc: "CASEFLOW",
            folder: create(
              :folder,
              ticknum: "95",
              tinum: "1445695",
              titrnum: "523454787S"
            )
          )
        )
      )
    end
    let!(:veteran5) { create(:veteran, file_number: "523454787") }

    scenario "Verify docket order is CVAC, AOD, then regular." do
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(text: "Central")
      click_button("Legacy Veterans Waiting")
      table_row = page.find("tr", id: "table-row-0")
      expect(table_row).to have_content("1545678", wait: 30)
      table_row = page.find("tr", id: "table-row-1")
      expect(table_row).to have_content("1645621")
      table_row = page.find("tr", id: "table-row-2")
      expect(table_row).to have_content("1645678")
      table_row = page.find("tr", id: "table-row-3")
      expect(table_row).to have_content("1445678")
      table_row = page.find("tr", id: "table-row-4")
      expect(table_row).to have_content("1445695")
    end
  end
end
