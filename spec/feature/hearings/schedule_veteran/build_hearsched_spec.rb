# frozen_string_literal: true

RSpec.feature "Schedule Veteran For A Hearing", :all_dbs do
  let!(:current_user) do
    user = create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"])
    User.authenticate!(user: user)
  end

  let(:other_user) { create(:user) }

  before do
    HearingsManagement.singleton.add_user(current_user)
    HearingAdmin.singleton.add_user(current_user)
    HearingsManagement.singleton.add_user(other_user)
    HearingAdmin.singleton.add_user(other_user)
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
    let!(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case, closest_regional_office: "C") }
    let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: legacy_appeal) }

    let!(:veteran) { create(:veteran, file_number: "123454787") }
    let!(:hearing_location_dropdown_label) { "Hearing Location" }
    let(:appellant_appeal_link_text) do
      "#{legacy_appeal.appellant[:first_name]} #{legacy_appeal.appellant[:last_name]} | #{veteran.file_number}"
    end
    let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_legacy_appeals }

    before do
      cache_appeals
    end

    def navigate_to_schedule_veteran_modal
      cache_appeals
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(text: "Central")
      click_button("Legacy Veterans Waiting")
      click_link appellant_appeal_link_text
      expect(page).not_to have_content("loading to VACOLS.", wait: 30)
      expect(page).to have_content("Currently active tasks", wait: 30)
      click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
      expect(page).to have_content("Time")
    end

    scenario "address from BGS is displayed in schedule veteran modal" do
      navigate_to_schedule_veteran_modal

      expect(page).to have_content FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_1
      expect(page).to have_content(
        "#{FakeConstants.BGS_SERVICE.DEFAULT_CITY}, " \
        "#{FakeConstants.BGS_SERVICE.DEFAULT_STATE} #{FakeConstants.BGS_SERVICE.DEFAULT_ZIP}"
      )
    end

    scenario "Schedule Veteran for central hearing" do
      navigate_to_schedule_veteran_modal
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
    let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_legacy_appeals }

    scenario "Schedule Veteran for video" do
      cache_appeals
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
      click_dropdown(name: "appealHearingLocation", text: "Holdrege, NE (VHA) 0 miles away")
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

    context "but facilities api throws an error" do
      before do
        facilities_response = ExternalApi::VADotGovService::FacilitiesResponse.new(
          HTTPI::Response.new(200, {}, {}.to_json)
        )
        allow(facilities_response).to receive(:data).and_return([])
        allow(facilities_response).to receive(:code).and_return(429)
        allow(VADotGovService).to receive(:get_distance).and_return(facilities_response)
      end

      scenario "Schedule Veteran for video error" do
        visit "queue/appeals/#{legacy_appeal.vacols_id}"
        click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
        expect(page).to have_content("Mapping service is temporarily unavailable. Please try again later.")
      end
    end
  end

  context "when scheduling an AMA hearing" do
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
        :with_post_intake_tasks,
        docket_type: Constants.AMA_DOCKETS.hearing,
        closest_regional_office: "RO39",
        veteran: create(:veteran)
      )
    end
    let(:incarcerated_veteran_task_instructions) { "Incarcerated veteran task instructions" }
    let(:contested_claimant_task_instructions) { "Contested claimant task instructions" }
    let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_ama_appeals }

    before do
      cache_appeals
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

      click_dropdown({ text: other_user.full_name }, find(".cf-modal-body"))
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
        click_dropdown(text: Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label)

        # On hold
        click_dropdown({ text: "15 days" }, find(".cf-modal-body"))
        fill_in "Notes:", with: "Waiting for response"

        click_on(COPY::MODAL_SUBMIT_BUTTON)

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
      expect(page).to_not have_content("Finding hearing locations", wait: 30)
      click_dropdown(name: "appealHearingLocation", text: "Holdrege, NE (VHA) 0 miles away")
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
          ),
          closest_regional_office: "C"
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
          ),
          closest_regional_office: "C"
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
          ),
          closest_regional_office: "C"
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
          ),
          closest_regional_office: "C"
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
          ),
          closest_regional_office: "C"
        )
      )
    end
    let!(:veteran5) { create(:veteran, file_number: "523454787") }
    let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_legacy_appeals }

    scenario "Verify docket order is CVAC, AOD, then regular." do
      cache_appeals
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

  context "With a full hearing day" do
    let(:appeal) { create(:appeal) }
    let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal) }
    let!(:hearing_day) do
      create(
        :hearing_day,
        scheduled_for: Time.zone.today + 5,
        request_type: HearingDay::REQUEST_TYPES[:video],
        regional_office: "RO17"
      )
    end
    let!(:hearings) do
      (1...hearing_day.total_slots + 1).map do |idx|
        create(
          :hearing,
          appeal: create(:appeal, receipt_date: Date.new(2019, 1, idx)),
          hearing_day: hearing_day
        )
      end
    end

    scenario "can still schedule veteran successfully" do
      visit "/queue/appeals/#{appeal.external_id}"
      click_dropdown(text: "Schedule Veteran")
      click_dropdown({ text: RegionalOffice.find!("RO17").city }, find(".cf-modal-body"))
      click_dropdown(
        text: "#{hearing_day.scheduled_for.to_formatted_s(:short_date)} (12/12)",
        name: "hearingDate"
      )

      expect(page).to have_content(COPY::SCHEDULE_VETERAN_FULL_HEARING_DAY_TITLE)
      expect(page).to have_content(COPY::SCHEDULE_VETERAN_FULL_HEARING_DAY_MESSAGE_DETAIL)

      click_dropdown(
        text: "Holdrege, NE (VHA) 0 miles away",
        name: "appealHearingLocation"
      )
      click_dropdown(text: "10:00 am", name: "optionalHearingTime1")
      click_button("Schedule")

      expect(page).to have_content(COPY::SCHEDULE_VETERAN_SUCCESS_MESSAGE_DETAIL)
    end
  end

  context "No upcoming hearing days" do
    scenario "Show status message for empty upcoming hearing days" do
      visit "hearings/schedule/assign"
      click_dropdown(text: "Winston-Salem, NC")
      expect(page).to have_content("No upcoming hearing days")
    end
  end

  context "Pagination for Assign Hearings Table" do
    let!(:hearing_day) do
      create(
        :hearing_day,
        request_type: HearingDay::REQUEST_TYPES[:video],
        scheduled_for: Time.zone.today + 60.days,
        regional_office: "RO39"
      )
    end

    let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_ama_appeals }
    let(:unassigned_count) { 3 }
    let(:regional_office) { "RO39" }
    
    def create_ama_appeals
      appeal1 = create(
        :appeal,
        closest_regional_office: regional_office,
        veteran: create(:veteran, participant_id: 1)
      )
      AvailableHearingLocations.create(
        appeal: appeal1,
        city: "Los Angeles",
        state: "CA",
        distance: 89,
        facility_type: "vet_center"
      )
      AvailableHearingLocations.create(
        appeal: appeal1,
        facility_id: "vba_372",
        city: "San Jose",
        state: "CA",
        distance: 34,
        facility_type: "va_benefits_facility"
      )
      AvailableHearingLocations.create(
        appeal: appeal1,
        city: "San Francisco",
        state: "CA",
        distance: 76,
        classification: "Regional Office",
        facility_type: "va_benefits_facility"
      )

      appeal2 = create(
        :appeal,
        closest_regional_office: regional_office,
        veteran: create(:veteran, participant_id: 2)
      )
      AvailableHearingLocations.create(
        appeal: appeal2,
        city: "Los Angeles",
        state: "CA",
        distance: 23,
        facility_type: "vet_center"
      )
      AvailableHearingLocations.create(
        appeal: appeal2,
        facility_id: "vba_372",
        city: "San Jose",
        state: "CA",
        distance: 34,
        facility_type: "va_benefits_facility"
      )
      AvailableHearingLocations.create(
        appeal: appeal2,
        city: "San Francisco",
        state: "CA",
        distance: 76,
        classification: "Regional Office",
        facility_type: "va_benefits_facility"
      )

      appeal3 = create(
        :appeal,
        closest_regional_office: regional_office,
        veteran: create(:veteran, participant_id: 3)
      )
      AvailableHearingLocations.create(
        appeal: appeal3,
        city: "Los Angeles",
        state: "CA",
        distance: 89,
        facility_type: "vet_center"
      )
      AvailableHearingLocations.create(
        appeal: appeal3,
        facility_id: "vba_372",
        city: "San Jose",
        state: "CA",
        distance: 34,
        facility_type: "va_benefits_facility"
      )
      AvailableHearingLocations.create(
        appeal: appeal3,
        city: "San Francisco",
        state: "CA",
        distance: 13,
        classification: "Regional Office",
        facility_type: "va_benefits_facility"
      )
      create(:schedule_hearing_task, appeal: appeal1)
      create(:schedule_hearing_task, appeal: appeal2)
      create(:schedule_hearing_task, appeal: appeal3)
    end

    def navigate_to_ama_tab
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(text: "Denver")
      expect(page).to have_content("AMA Veterans Waiting")
      click_button("AMA Veterans Waiting")
    end

    context "Specify page number" do
      let(:unassigned_count) { 20 }
      let(:default_cases_for_page) { 15 }
      let(:page_no) { 2 }
      let(:query_string) do
        "#{Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}="\
        "#{Constants.QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME}"\
        "&regional_office_key=#{regional_office}"\
        "&#{Constants.QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM}=#{page_no}"
      end

      it "shows correct number of tasks" do     
        20.times do 
          appeal = create(:appeal, closest_regional_office: "RO39")
          create(:schedule_hearing_task, appeal: appeal)
        end
        cache_appeals

        visit "hearings/schedule/assign/?#{query_string}"

        expect(page).to have_content(
          "Viewing #{default_cases_for_page + 1}-#{unassigned_count} of #{unassigned_count} total"
        )
        page.find_all(".cf-current-page").each { |btn| expect(btn).to have_content(page_no) }
        expect(find("tbody").find_all("tr").length).to eq(unassigned_count - default_cases_for_page)
      end
    end

    context "Filter by SuggestedHearingLocation column" do
      before do
        create_ama_appeals
        cache_appeals
        navigate_to_ama_tab
      end

      it "filters are correct, and filter as expected" do
        step "check if there are the right number of rows for the ama tab" do
          expect(find("tbody").find_all("tr").length).to eq(unassigned_count)
        end

        step "check if the filter options are as expected" do
          page.find(".unselected-filter-icon-inner", match: :first).click
          expect(page).to have_content("#{Appeal.first.suggested_hearing_location.formatted_location} (1)")
          expect(page).to have_content("#{Appeal.second.suggested_hearing_location.formatted_location} (1)")
          expect(page).to have_content("#{Appeal.third.suggested_hearing_location.formatted_location} (1)")
        end

        step "clicking on a filter reduces the number of results by the expect amount" do
          page.find("label", text: "#{Appeal.first.suggested_hearing_location.formatted_location} (1)").click
          expect(find("tbody").find_all("tr").length).to eq(1)
        end
      end
    end

    context "Filter by PowerOfAttorneyName column" do
      before do
        allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids).with(["1"]).and_return(
          {"1"=> {:representative_type=>"Attorney", :representative_name=>"Attorney One", :participant_id=>"1"}}
        )
        allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids).with(["2"]).and_return(
          {"2"=> {:representative_type=>"Attorney", :representative_name=>"Attorney Two", :participant_id=>"2"}}
        )
        allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids).with(["3"]).and_return(
          {"3"=> {:representative_type=>"Attorney", :representative_name=>"Attorney Three", :participant_id=>"3"}}
        )
        
        create_ama_appeals
        cache_appeals
        navigate_to_ama_tab
      end

      it "filters are correct, and filter as expected" do
        step "check if there are the right number of rows for the ama tab" do
          expect(find("tbody").find_all("tr").length).to eq(unassigned_count)
        end

        step "check if the filter options are as expected" do
          page.find_all("path.unselected-filter-icon-inner")[1].click
          expect(page).to have_content("#{Appeal.first.representative_name} (1)")
          expect(page).to have_content("#{Appeal.second.representative_name} (1)")
          expect(page).to have_content("#{Appeal.third.representative_name} (1)")
        end

        step "clicking on a filter reduces the number of results by the expect amount" do
          page.find("label", text: "#{Appeal.first.representative_name} (1)").click
          expect(find("tbody").find_all("tr").length).to eq(1)
        end
      end
    end

    context "Filter by <<blank>> value" do
      context "For Suggested Hearing Location column" do
        let(:unassigned_count) { 10 }
        before do
          unassigned_count.times do 
            appeal = create(:appeal, closest_regional_office: "RO39")
            create(:schedule_hearing_task, appeal: appeal)
          end
          cache_appeals
          navigate_to_ama_tab
        end

        it "shows zero tasks" do
          step "check if there are the right number of rows for the ama tab" do
            expect(find("tbody").find_all("tr").length).to eq(unassigned_count)
          end

          step "check if the filter options are as expected" do
            page.find(".unselected-filter-icon-inner", match: :first).click
            expect(page).to have_content("#{COPY::NULL_FILTER_LABEL} (#{unassigned_count})")
          end

          step "clicking on filter shows expected tasks" do
            page.find("label", text: "#{COPY::NULL_FILTER_LABEL} (#{unassigned_count})").click
            expect(page).not_to have_selector("tbody")
          end
        end
      end
    end
  end
end