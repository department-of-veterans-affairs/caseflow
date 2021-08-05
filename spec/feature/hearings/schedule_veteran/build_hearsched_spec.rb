# frozen_string_literal: true

##
# Tests various aspects of scheduling a hearing as an admin hearing coordinator
RSpec.feature "Schedule Veteran For A Hearing" do
  context "with an authorized user" do
    let!(:current_user) do
      user = create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"])
      User.authenticate!(user: user)
    end

    let(:other_user) { create(:user) }
    let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_legacy_appeals }
    let(:fill_in_veteran_email) { "vet@testingEmail.com" }
    let(:fill_in_representative_email) { "email@testingEmail.com" }
    let(:unscheduled_notes) { "Unscheduled notes" }
    let(:fill_in_unscheduled_notes) { "Fill in unscheduled notes" }

    before do
      HearingsManagement.singleton.add_user(current_user)
      HearingAdmin.singleton.add_user(current_user)
      HearingsManagement.singleton.add_user(other_user)
      HearingAdmin.singleton.add_user(other_user)
    end

    shared_context "hearing subtree" do
      let!(:root_task) { create(:root_task, appeal: appeal) }
      let!(:hearing_task) do
        create(:hearing_task, parent: root_task, instructions: [unscheduled_notes])
      end
      let!(:schedule_hearing_task) do
        create(:schedule_hearing_task, appeal: appeal, parent: hearing_task)
      end
    end

    shared_context "central_hearing" do
      let!(:hearing_day) { create(:hearing_day, scheduled_for: Time.zone.today + 30.days) }
      let!(:vacols_case) do
        create(
          :case, :central_office_hearing,
          bfcorlid: "123454787S",
          bfcurloc: "CASEFLOW"
        )
      end
      let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case, closest_regional_office: "C") }

      let!(:veteran) { create(:veteran, file_number: "123454787") }
      let!(:hearing_location_dropdown_label) { "Hearing Location" }
      let(:appellant_appeal_link_text) do
        "#{appeal.appellant[:first_name]} #{appeal.appellant[:last_name]} | #{veteran.file_number}"
      end

      let!(:expected_alert) do
        COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_TO_VIRTUAL"]["TITLE"] % appeal.veteran.name
      end

      def navigate_to_schedule_veteran
        visit "hearings/schedule/assign"
        expect(page).to have_content("Regional Office")
        click_dropdown(text: "Central")
        click_button("Legacy Veterans Waiting", exact: true)
        click_link appellant_appeal_link_text
        expect(page).not_to have_content("loading to VACOLS.", wait: 30)
        expect(page).to have_content("Currently active tasks", wait: 30)
        click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
        expect(page).to have_content("Time")
      end
    end

    shared_context "video_hearing" do |virtual_day = false|
      request_type = virtual_day ? HearingDay::REQUEST_TYPES[:virtual] : HearingDay::REQUEST_TYPES[:video]
      let(:first_slot_time) { nil }
      let!(:hearing_day) do
        create(
          :hearing_day,
          request_type: request_type,
          scheduled_for: Time.zone.today + 60.days,
          regional_office: "RO39",
          first_slot_time: first_slot_time
        )
      end
      let!(:staff) { create(:staff, stafkey: "RO39", stc2: 2, stc3: 3, stc4: 4) }
      let!(:vacols_case) do
        create(
          :case,
          :video_hearing_requested,
          folder: create(:folder, tinum: "docket-number"),
          bfcorlid: "123456789S",
          bfcurloc: "CASEFLOW",
          bfregoff: "RO39"
        )
      end
      let!(:appeal) do
        create(
          :legacy_appeal,
          vacols_case: vacols_case,
          closest_regional_office: "RO39"
        )
      end
      let!(:veteran) { create(:veteran, file_number: "123456789") }
      let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_legacy_appeals }
      let(:room_label) { HearingRooms.find!(hearing_day.room)&.label }

      let!(:expected_alert) do
        COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_TO_VIRTUAL"]["TITLE"] % appeal.veteran.name
      end

      def navigate_to_schedule_veteran
        visit "hearings/schedule/assign"
        expect(page).to have_content("Regional Office")
        click_dropdown(text: "Denver, CO")
        click_button("Legacy Veterans Waiting", exact: true)
        appeal_link = page.find(:xpath, "//tbody/tr/td[2]/a")
        appeal_link.click
        expect(page).not_to have_content("loading to VACOLS.", wait: 30)
        expect(page).to have_content("Currently active tasks", wait: 30)
        click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
        expect(page).to have_content("Time")
      end
    end

    shared_context "ama_hearing" do
      let!(:room) { "1" }
      let!(:regional_office) { "RO39" }
      let!(:hearing_day) do
        create(
          :hearing_day,
          request_type: HearingDay::REQUEST_TYPES[:video],
          scheduled_for: Time.zone.today + 160,
          regional_office: regional_office,
          room: room
        )
      end
      let!(:staff) { create(:staff, stafkey: regional_office, stc2: 2, stc3: 3, stc4: 4) }
      let!(:appeal) do
        create(
          :appeal,
          :with_post_intake_tasks,
          docket_type: Constants.AMA_DOCKETS.hearing,
          closest_regional_office: regional_office,
          veteran: create(:veteran)
        )
      end
      let(:incarcerated_veteran_task_instructions) { "Incarcerated veteran task instructions" }
      let(:contested_claimant_task_instructions) { "Contested claimant task instructions" }
      let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_ama_appeals }
    end

    shared_context "legacy_hearing" do
      let(:regional_office) { "RO39" }
      let(:vacols_case) do
        create(
          :case,
          bfregoff: regional_office
        )
      end
      let!(:legacy_appeal) do
        create(
          :legacy_appeal,
          :with_schedule_hearing_tasks,
          :with_veteran,
          closest_regional_office: regional_office,
          vacols_case: vacols_case
        )
      end
    end

    shared_context "full_hearing_day" do
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
    end

    shared_context "open_hearing" do
      let(:regional_office) { "RO39" }
      let(:hearing_day) do
        create(
          :hearing_day,
          request_type: HearingDay::REQUEST_TYPES[:video],
          scheduled_for: Time.zone.today + 160,
          regional_office: regional_office
        )
      end
      let(:appeal) do
        create(
          :appeal,
          :hearing_docket,
          :with_post_intake_tasks,
          closest_regional_office: regional_office
        )
      end
      let!(:hearing) do
        create(
          :hearing,
          :with_tasks,
          appeal: appeal,
          hearing_day: hearing_day,
          regional_office: regional_office
        )
      end
    end

    # Method to convert time zones
    def convert_local_time_to_eastern_timezone(time)
      # Reach through hearing_day for the regional_office timezone
      ro_timezone = if hearing_day.central_office?
                      "America/New_York"
                    else
                      RegionalOffice.find!(hearing_day.regional_office).timezone
                    end

      # Get the timezone abbreviation like "EDT", "PDT", from the long timezone
      ro_timezone_abbreviation = Time.zone.now.in_time_zone(ro_timezone).strftime("%Z")

      # Parse the local time string (like "09:00 PDT"), then produce a result in EDT like "11:30 EDT"
      Time.zone.parse("#{time} #{ro_timezone_abbreviation}").in_time_zone("America/New_York").strftime("%-I:%M %p %Z")
    end

    # Method to choose either the hearing time slot buttons or hearing time radio buttons
    def select_hearing_time(time)
      find(".cf-form-radio-option", text: time).click
    end

    def zone_is_eastern(regional_office)
      RegionalOffice.find!(regional_office).timezone == "America/New_York"
    end

    # Method to choose the custom hearing time dropdown
    def select_custom_hearing_time(time)
      click_dropdown(text: /^(#{time} (A|a)(M|m)( E)?)/, name: "optionalHearingTime0")
    end

    def slots_select_hearing_time(time)
      find(".time-slot-button", text: "#{time} EDT").click
    end

    def slots_select_custom_hearing_time(time)
      find(".time-slot-button-toggle", text: "Choose a custom time").click
      # Type in the time, add am, press enter with \n, then tab away
      # to allow the select to update
      time_select_input = find(".time-select").find("input")
      time_select_input.send_keys time, :enter, :tab
      click_button("Choose time")
    end

    def format_hearing_day(hearing_day, detail_label = nil, total_slots = 0)
      # Initialize the label with the formatted hearing day
      label = hearing_day.scheduled_for.strftime("%a %b %-d").to_s

      # Add the Formatted request type
      label +=  "· #{Hearing::HEARING_TYPES[hearing_day.request_type.to_sym]}"

      # Add the Count of scheduled
      label +=  "· #{total_slots} of #{hearing_day.total_slots} scheduled"

      # Add the details label
      unless detail_label.nil?
        label += "· #{detail_label}"
      end

      # Return the formatted label
      label
    end

    shared_examples "scheduling a central hearing" do
      include_context "central_hearing"
      include_context "hearing subtree"

      before { cache_appeals }

      scenario "and address from BGS is displayed in schedule veteran workflow" do
        navigate_to_schedule_veteran

        expect(page).to have_content FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_1
        expect(page).to have_content(
          "#{FakeConstants.BGS_SERVICE.DEFAULT_CITY}, " \
          "#{FakeConstants.BGS_SERVICE.DEFAULT_STATE} #{FakeConstants.BGS_SERVICE.DEFAULT_ZIP}"
        )
      end

      scenario "Schedule Veteran for central hearing" do
        navigate_to_schedule_veteran
        # Wait for the contents of the dropdown to finish loading before clicking into the dropdown.
        expect(page).to have_content(hearing_location_dropdown_label)
        click_dropdown(name: "appealHearingLocation", text: "Holdrege, NE (VHA) 0 miles away")
        select_hearing_time("9:00")

        if FeatureToggle.enabled?(:schedule_veteran_virtual_hearing)
          # Fill in Unscheduled Notes
          expect(page).to have_content(unscheduled_notes)
          fill_in "Notes", with: fill_in_unscheduled_notes
        end

        click_button("Schedule", exact: true)
        click_on "Back to Schedule Veterans"
        expect(page).to have_content("Schedule Veterans")
        click_button("Scheduled Veterans", exact: true)
        expect(VACOLS::Case.where(bfcorlid: "123454787S"))
        click_button("Legacy Veterans Waiting", exact: true)
        expect(page.has_no_content?("123454787S")).to eq(true)
        expect(page).to have_content("There are no schedulable veterans")
        expect(VACOLS::CaseHearing.first.folder_nr).to eq vacols_case.bfkey

        if FeatureToggle.enabled?(:schedule_veteran_virtual_hearing)
          # Ensure new hearing has the unscheduled notes
          expect(VACOLS::CaseHearing.first.notes1).to eq fill_in_unscheduled_notes
          expect(LegacyHearing.last.notes).to eq(fill_in_unscheduled_notes)
        end
      end
    end

    shared_examples "scheduling a video hearing" do
      include_context "video_hearing"
      include_context "hearing subtree"

      scenario "Schedule Veteran for video" do
        cache_appeals
        navigate_to_schedule_veteran
        select_hearing_time("8:30")
        click_dropdown(name: "appealHearingLocation", text: "Holdrege, NE (VHA) 0 miles away")
        expect(page).not_to have_content("Could not find hearing locations for this veteran")
        expect(page).not_to have_content("There are no upcoming hearing dates for this regional office.")
        click_dropdown(
          text: format_hearing_day(hearing_day, room_label),
          name: "hearingDate"
        )

        if FeatureToggle.enabled?(:schedule_veteran_virtual_hearing)
          # Fill in Unscheduled Notes
          expect(page).to have_content(unscheduled_notes)
          fill_in "Notes", with: fill_in_unscheduled_notes
        end

        click_button("Schedule", exact: true)
        click_on "Back to Schedule Veterans"
        expect(page).to have_content("Schedule Veterans")
        click_button("Scheduled Veterans", exact: true)
        expect(VACOLS::Case.where(bfcorlid: "123456789S"))
        click_button("Legacy Veterans Waiting", exact: true)
        expect(page.has_no_content?("123456789S")).to eq(true)
        expect(page).to have_content("There are no schedulable veterans")
        expect(VACOLS::CaseHearing.first.folder_nr).to eq vacols_case.bfkey

        if FeatureToggle.enabled?(:schedule_veteran_virtual_hearing)
          # Ensure new hearing has the unscheduled notes
          expect(VACOLS::CaseHearing.first.notes1).to eq fill_in_unscheduled_notes
          expect(LegacyHearing.last.notes).to eq(fill_in_unscheduled_notes)
        end
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
          visit "queue/appeals/#{appeal.vacols_id}"
          click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
          expect(page).to have_css(
            ".usa-alert-error",
            text: "Mapping service is temporarily unavailable. Please try again later."
          )
        end
      end

      shared_examples "hearing time display" do
        scenario "Hearing time displays as expected" do
          cache_appeals
          navigate_to_schedule_veteran
          click_dropdown(name: "appealHearingLocation", text: "Holdrege, NE (VHA) 0 miles away")
          click_dropdown(
            text: format_hearing_day(hearing_day, room_label),
            name: "hearingDate"
          )
          expect(page).to have_content("Hearing Time")
          if first_slot_time.nil?
            expect(find(".cf-form-radio-option", text: "8:30")).not_to eq(nil)
            select_hearing_time("12:30")
          else
            expect(page).not_to have_selector(".cf-form-radio-option")
            expect(page).to have_content(readonly_time_text)
          end

          click_button("Schedule", exact: true)
          expect(page).to have_content("You have successfully assigned")

          new_hearing = hearing_day.reload.open_hearings.first
          scheduled_time = new_hearing.scheduled_for.in_time_zone("America/Denver").strftime("%I:%M")
          expect(scheduled_time).to eq(expected_time)
        end
      end

      context "Hearing time field based first slot time" do
        context "first slot time is null" do
          let(:expected_time) { "12:30" }
          include_examples "hearing time display"
        end

        context "first slot time is '08:30'" do
          let(:first_slot_time) { "10:30" }
          let(:expected_time) { "08:30" }
          let(:readonly_time_text) { "8:30 AM Mountain / 10:30 AM Eastern" }
          include_examples "hearing time display"
        end

        context "first slot time is '12:30'" do
          let(:first_slot_time) { "14:30" }
          let(:expected_time) { "12:30" }
          let(:readonly_time_text) { "12:30 PM Mountain / 2:30 PM Eastern" }
          include_examples "hearing time display"
        end
      end
    end

    shared_examples "scheduling an AMA hearing" do
      include_context "ama_hearing"

      before { cache_appeals }

      scenario "Can create multiple admin actions and reassign them" do
        visit "hearings/schedule/assign"
        expect(page).to have_content("Regional Office")
        click_dropdown(text: "Denver")
        click_button("AMA Veterans Waiting", exact: true)
        click_on "Bob"

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
        incarcerated_row = find(
          "dd",
          text: HearingAdminActionIncarceratedVeteranTask.label
        ).find(:xpath, "ancestor::tr")
        incarcerated_row.click_on(
          COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL
        )
        expect(incarcerated_row).to have_content incarcerated_veteran_task_instructions

        contested_row = find("dd", text: HearingAdminActionContestedClaimantTask.label).find(:xpath, "ancestor::tr")
        contested_row.click_on(
          COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL
        )
        expect(contested_row).to have_content contested_claimant_task_instructions

        within all("div", class: "cf-select", count: 2).first do
          click_dropdown(text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h[:label])
        end

        click_on "Submit"

        # Your queue
        visit "/queue"
        click_on "Bob"

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

        expect(page).to have_content(appeal.veteran_full_name)
      end

      scenario "Schedule Veteran for a video hearing with admin actions that can be put on hold and completed" do
        # Do the first part of the test in the past so we can wait for our hold to complete.
        Timecop.travel(17.days.ago) do
          visit "hearings/schedule/assign"
          expect(page).to have_content("Regional Office")
          click_dropdown(text: "Denver")
          click_button("AMA Veterans Waiting", exact: true)
          click_on "Bob"

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
          click_on "Bob"
          click_dropdown(text: Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label)

          # On hold
          click_dropdown({ text: "15 days" }, find(".cf-modal-body"))
          fill_in "Notes:", with: "Waiting for response"

          click_on(COPY::MODAL_SUBMIT_BUTTON)

          expect(page).to have_content("case has been placed on hold")
        end

        # Refresh the page in the present, and the hold should be completed.
        TaskTimerJob.perform_now
        visit "/queue"
        click_on "Bob"

        # Complete the admin action
        click_dropdown(text: Constants.TASK_ACTIONS.MARK_COMPLETE.to_h[:label])
        click_on "Mark complete"

        expect(page).to have_content("has been marked complete")

        # Schedule veteran!
        visit "hearings/schedule/assign"
        expect(page).to have_content("Regional Office")
        click_dropdown(text: "Denver")
        click_button("AMA Veterans Waiting", exact: true)

        click_on "Bob"
        click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
        click_dropdown({ text: "Denver" }, find(".dropdown-regionalOffice"))
        click_dropdown(name: "hearingDate", index: 1)

        select_hearing_time("8:30")
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
        click_button("AMA Veterans Waiting", exact: true)
        expect(page).to have_content("There are no schedulable veterans")
      end

      context "and room is null" do
        let(:room) { nil }

        scenario "can schedule a veteran without an error" do
          visit "hearings/schedule/assign"

          click_dropdown(text: "Denver")
          click_button("AMA Veterans Waiting", exact: true)
          click_on "Bob"

          click_dropdown(text: "Schedule Veteran")
          click_dropdown(
            text: RegionalOffice.find!(regional_office).city,
            name: "regionalOffice"
          )
          click_dropdown(text: format_hearing_day(hearing_day), name: "hearingDate")

          click_dropdown(
            text: "Holdrege, NE (VHA) 0 miles away",
            name: "appealHearingLocation"
          )
          select_custom_hearing_time("10:15")
          click_button("Schedule", exact: true)

          expect(page).to have_content(COPY::SCHEDULE_VETERAN_SUCCESS_MESSAGE_DETAIL)
        end

        scenario "should not see room displayed under Available Hearing Days and Assign Hearing Tabs" do
          visit "hearings/schedule/assign"

          click_dropdown(text: "Denver")
          click_button("AMA Veterans Waiting", exact: true)
          click_on "Bob"

          click_dropdown(text: "Schedule Veteran")
          click_dropdown(
            text: RegionalOffice.find!(regional_office).city,
            name: "regionalOffice"
          )
          click_dropdown(
            text: format_hearing_day(hearing_day),
            name: "hearingDate"
          )
          click_dropdown(
            text: "Holdrege, NE (VHA) 0 miles away",
            name: "appealHearingLocation"
          )
          select_custom_hearing_time("10:15")
          click_button("Schedule", exact: true)
          click_on "Back to Schedule Veterans"

          expect(page).not_to have_content("null")
        end
      end
    end

    shared_examples "scheduling a Legacy hearing" do
      include_context "legacy_hearing"

      before { cache_appeals }

      context "and room is null" do
        let!(:hearing_day) do
          create(
            :hearing_day,
            request_type: HearingDay::REQUEST_TYPES[:video],
            scheduled_for: Time.zone.today + 160,
            regional_office: regional_office,
            room: nil
          )
        end

        scenario "can schedule a veteran without an error" do
          visit "hearings/schedule/assign"

          click_dropdown(text: "Denver")
          click_button("Legacy Veterans Waiting", exact: true)
          click_on "Bob Smith"

          click_dropdown(text: "Schedule Veteran")
          click_dropdown(
            text: RegionalOffice.find!(regional_office).city,
            name: "regionalOffice"
          )
          click_dropdown(
            text: format_hearing_day(hearing_day),
            name: "hearingDate"
          )
          click_dropdown(
            text: "Holdrege, NE (VHA) 0 miles away",
            name: "appealHearingLocation"
          )
          select_custom_hearing_time("10:15")
          click_button("Schedule", exact: true)

          expect(page).to have_content(COPY::SCHEDULE_VETERAN_SUCCESS_MESSAGE_DETAIL)
        end
      end
    end

    shared_examples "an appeal with a full hearing day" do
      include_context "full_hearing_day"

      scenario "can still schedule veteran successfully" do
        visit "/queue/appeals/#{appeal.external_id}"

        total_slots = hearing_day.total_slots

        click_dropdown(text: "Schedule Veteran")
        click_dropdown(name: "regionalOffice", text: "St. Petersburg, FL")
        click_dropdown(
          text: format_hearing_day(hearing_day, nil, total_slots),
          name: "hearingDate"
        )

        expect(page).to have_content(COPY::SCHEDULE_VETERAN_FULL_HEARING_DAY_TITLE)
        expect(page).to have_content(COPY::SCHEDULE_VETERAN_FULL_HEARING_DAY_MESSAGE_DETAIL)

        click_dropdown(
          text: "Holdrege, NE (VHA) 0 miles away",
          name: "appealHearingLocation"
        )
        select_custom_hearing_time("10:15")
        click_button("Schedule", exact: true)

        expect(page).to have_content(COPY::SCHEDULE_VETERAN_SUCCESS_MESSAGE_DETAIL)
      end
    end

    shared_examples "an appeal where there is an open hearing" do
      include_context "open_hearing"

      scenario "shows an error message in the schedule veteran's modal" do
        visit "queue/appeals/#{appeal.external_id}"
        # Expected dropdowns on page:
        #   [0] - Assign disposition task
        #   [1] - Schedule hearing task
        within page.all(".cf-form-dropdown")[1] do
          click_dropdown(text: "Schedule Veteran")
        end
        expect(page).to have_content("Open Hearing")
      end
    end

    shared_examples "scheduling a virtual hearing" do |ro_key, time, slots = false|
      scenario "can successfully schedule virtual hearing" do
        navigate_to_schedule_veteran
        expect(page).to have_content("Schedule Veteran for a Hearing")
        click_dropdown(name: "hearingType", text: "Virtual")
        click_dropdown(name: "hearingDate", index: 1)

        # Only one of these three gets called, they each represent a different
        # way to select a hearing time
        select_custom_hearing_time(time) unless slots
        slots_select_hearing_time(time) if slots == "slot"
        slots_select_custom_hearing_time(time) if slots == "custom"

        # Fill in appellant details
        click_dropdown(name: "appellantTz", index: 1)
        fill_in "Veteran Email", with: fill_in_veteran_email

        # Fill in POA/Representative details
        click_dropdown(name: "representativeTz", index: 1)
        fill_in "POA/Representative Email", with: fill_in_representative_email

        # Fill in Unscheduled Notes
        expect(page).to have_content(unscheduled_notes)
        fill_in "Notes", with: fill_in_unscheduled_notes

        click_button("Schedule")

        expect(page).to have_content(expected_alert)
        expect(VirtualHearing.count).to eq(1)
        expect(LegacyHearing.where(hearing_day_id: hearing_day.id).count).to eq 1

        # Retrieve the newly created hearing
        new_hearing = LegacyHearing.find_by(hearing_day_id: hearing_day.id)

        # Test the hearing was created correctly with the virtual hearing
        expect(new_hearing.hearing_location).to eq nil
        expect(new_hearing.virtual_hearing).to eq VirtualHearing.first
        expect(new_hearing.regional_office.key).to eq ro_key

        # Test the emails were sent
        events = SentHearingEmailEvent.where(hearing_id: new_hearing.id)
        expect(events.count).to eq 2
        expect(events.where(sent_by_id: current_user.id).count).to eq 2
        expect(events.where(email_type: "confirmation").count).to eq 2
        expect(events.where(email_address: fill_in_veteran_email).count).to eq 1
        expect(events.sent_to_appellant.count).to eq 1
        expect(events.where(email_address: fill_in_representative_email).count).to eq 1
        expect(events.where(recipient_role: "representative").count).to eq 1

        # Ensure new hearing has the unscheduled notes
        expect(new_hearing.notes).to eq(fill_in_unscheduled_notes)
      end
    end

    shared_examples "change from Central hearing" do
      include_context "central_hearing"
      include_context "hearing subtree"

      before { cache_appeals }

      it_behaves_like "scheduling a virtual hearing", "C", "11:00"
    end

    shared_examples "change from Video hearing" do
      include_context "video_hearing"
      include_context "hearing subtree"

      before { cache_appeals }

      it_behaves_like "scheduling a virtual hearing", "RO39", "10:30"
    end

    shared_examples "withdraw a hearing" do
      def schedule_hearing(appeal_link)
        visit appeal_link
        click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
        click_dropdown(name: "appealHearingLocation", text: "Holdrege, NE (VHA) 0 miles away")

        room_label = HearingRooms.find!(hearing_day.room)&.label

        click_dropdown(
          text: format_hearing_day(hearing_day, room_label),
          name: "hearingDate"
        )
        select_hearing_time("8:30")
        click_button("Schedule", exact: true)
      end

      shared_examples "withdrawing ama hearing" do |scheduled = false|
        scenario "Withdraw Veteran's hearing request" do
          visit "queue/appeals/#{appeal.uuid}"

          click_dropdown(text: Constants.TASK_ACTIONS.WITHDRAW_HEARING.to_h[:label])
          expect(page).to have_content(COPY::WITHDRAW_HEARING["AMA"]["MODAL_BODY"])
          fill_in "taskInstructions", with: "Withdrawing hearing"

          click_on "Submit"

          expect(page).to have_content("You have successfully withdrawn")
          expect(page).to have_content(COPY::WITHDRAW_HEARING["AMA"]["SUCCESS_MESSAGE"])
          expect(appeal.tasks.of_type(:EvidenceSubmissionWindowTask).count).to eq(1)

          if scheduled
            expect(appeal.tasks.of_type(:ScheduleHearingTask).first.status).to eq(
              Constants.TASK_STATUSES.completed
            )
            expect(appeal.tasks.of_type(:AssignHearingDispositionTask).first.status).to eq(
              Constants.TASK_STATUSES.cancelled
            )
            expect(appeal.hearings.last.cancelled?).to eq(true)
          else
            expect(appeal.tasks.of_type(:ScheduleHearingTask).first.status).to eq(
              Constants.TASK_STATUSES.cancelled
            )
          end
        end
      end

      shared_examples "withdrawing legacy hearing" do |scheduled = false|
        scenario "Withdraw Veteran's hearing request" do
          visit "queue/appeals/#{legacy_appeal.vacols_id}"

          click_dropdown(text: Constants.TASK_ACTIONS.WITHDRAW_HEARING.to_h[:label])
          expect(page.html).to include(
            COPY::WITHDRAW_HEARING["LEGACY_NON_COLOCATED_PRIVATE_ATTORNEY"]["MODAL_BODY"]
          )
          fill_in "taskInstructions", with: "Withdrawing hearing"

          click_on "Submit"

          expect(page).to have_content("You have successfully withdrawn")
          expect(page.html).to include(
            COPY::WITHDRAW_HEARING["LEGACY_NON_COLOCATED_PRIVATE_ATTORNEY"]["SUCCESS_MESSAGE"]
          )

          expect(legacy_appeal.case_record.bfhr).to eq("5")
          expect(legacy_appeal.case_record.bfha).to eq("5")

          if scheduled
            expect(legacy_appeal.tasks.of_type(:ScheduleHearingTask).first.status).to eq(
              Constants.TASK_STATUSES.completed
            )
            expect(legacy_appeal.tasks.of_type(:AssignHearingDispositionTask).first.status).to eq(
              Constants.TASK_STATUSES.cancelled
            )
            expect(legacy_appeal.hearings.last.cancelled?).to eq(true)
          else
            expect(legacy_appeal.tasks.of_type(:ScheduleHearingTask).first.status).to eq(
              Constants.TASK_STATUSES.cancelled
            )
          end
        end
      end

      before { cache_appeals }

      context "Scheduled hearing" do
        context "AMA appeal" do
          include_context "ama_hearing"

          before do
            schedule_hearing("queue/appeals/#{appeal.uuid}")
          end

          it_behaves_like "withdrawing ama hearing", true
        end

        context "Legacy appeal" do
          include_context "legacy_hearing"

          let!(:hearing_day) do
            create(
              :hearing_day,
              request_type: HearingDay::REQUEST_TYPES[:video],
              scheduled_for: Time.zone.today + 160,
              regional_office: regional_office,
              room: "1"
            )
          end

          before do
            schedule_hearing("queue/appeals/#{legacy_appeal.vacols_id}")
          end

          it_behaves_like "withdrawing legacy hearing", true
        end
      end

      context "Unscheduled hearing" do
        context "AMA appeal" do
          include_context "ama_hearing"

          it_behaves_like "withdrawing ama hearing"
        end

        context "Legacy appeal" do
          include_context "legacy_hearing"

          let!(:hearing_day) do
            create(
              :hearing_day,
              request_type: HearingDay::REQUEST_TYPES[:video],
              scheduled_for: Time.zone.today + 160,
              regional_office: regional_office,
              room: "1"
            )
          end

          it_behaves_like "withdrawing legacy hearing"
        end
      end
    end

    shared_examples "scheduling a hearing on a virtual hearing day using a slot button" do
      include_context "video_hearing", true
      include_context "hearing subtree"

      before { cache_appeals }

      # Use the timeslot button
      it_behaves_like "scheduling a virtual hearing", "RO39", "10:30 AM", "slot"
    end

    shared_examples "scheduling a hearing on a virtual hearing day using a custom time" do
      include_context "video_hearing", true
      include_context "hearing subtree"

      before { cache_appeals }

      # Use the timeslot custom time modal
      it_behaves_like "scheduling a virtual hearing", "RO39", "10:45 AM", "custom"
    end

    context "with enable_time_slots feature disabled" do
      # Ensure the feature flag is enabled before testing
      before do
        FeatureToggle.disable!(:enable_hearing_time_slots)
      end

      context "with schedule direct to video/virtual feature enabled" do
        # Ensure the feature flag is enabled before testing
        before do
          FeatureToggle.enable!(:schedule_veteran_virtual_hearing)
        end

        it_behaves_like "scheduling a central hearing"

        it_behaves_like "scheduling a video hearing"

        it_behaves_like "scheduling an AMA hearing"

        it_behaves_like "scheduling a Legacy hearing"

        it_behaves_like "an appeal with a full hearing day"

        it_behaves_like "an appeal where there is an open hearing"

        it_behaves_like "change from Central hearing"

        it_behaves_like "change from Video hearing"

        it_behaves_like "withdraw a hearing"
      end
    end

    context "with enable_time_slots feature enabled" do
      # Ensure the feature flag is enabled before testing
      before do
        FeatureToggle.enable!(:schedule_veteran_virtual_hearing)
        FeatureToggle.enable!(:enable_hearing_time_slots)
      end

      # These are the only feature tests that create 'R' virtual
      # hearing days and should show timeslots
      it_behaves_like "scheduling a hearing on a virtual hearing day using a slot button"
      it_behaves_like "scheduling a hearing on a virtual hearing day using a custom time"

      # TimeSlots will only ever show for a virtual hearing day
      # so these tests should run the same regardless of
      # :enable_hearing_time_slots
      it_behaves_like "scheduling a central hearing"

      it_behaves_like "scheduling a video hearing"

      it_behaves_like "scheduling an AMA hearing"

      it_behaves_like "scheduling a Legacy hearing"

      it_behaves_like "an appeal with a full hearing day"

      it_behaves_like "an appeal where there is an open hearing"

      it_behaves_like "change from Central hearing"

      it_behaves_like "change from Video hearing"

      it_behaves_like "withdraw a hearing"
    end
  end

  context "with an unauthorized user" do
    let!(:current_user) do
      user = create(:user)
      User.authenticate!(user: user)
    end

    let!(:regional_office) { "RO39" }
    let!(:appeal) do
      create(
        :appeal,
        :with_schedule_hearing_tasks,
        docket_type: Constants.AMA_DOCKETS.hearing,
        closest_regional_office: regional_office,
        veteran: create(:veteran)
      )
    end

    scenario "redirects to the case details page" do
      task = appeal.tasks.find_by(type: "ScheduleHearingTask")
      params = "?action=reschedule&disposition=scheduled_in_error"
      visit "queue/appeals/#{appeal.external_id}/tasks/#{task.id}/schedule_veteran#{params}"

      expect(page).to have_current_path("/queue/appeals/#{appeal.external_id}")
    end
  end
end
