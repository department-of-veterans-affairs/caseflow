# frozen_string_literal: true

##
# Tests various aspects of scheduling a hearing as an admin hearing coordinator
RSpec.feature "Schedule Veteran For A Hearing" do
  let!(:current_user) do
    user = create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"])
    User.authenticate!(user: user)
  end

  let(:other_user) { create(:user) }
  let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_legacy_appeals }
  let(:fill_in_veteran_email) { "vet@testingEmail.com" }
  let(:fill_in_representative_email) { "email@testingEmail.com" }

  before do
    HearingsManagement.singleton.add_user(current_user)
    HearingAdmin.singleton.add_user(current_user)
    HearingsManagement.singleton.add_user(other_user)
    HearingAdmin.singleton.add_user(other_user)
  end

  shared_context "central_hearings" do
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

    let!(:expected_alert) do
      COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_TO_VIRTUAL"]["TITLE"] % legacy_appeal.veteran.name
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

  shared_context "video_hearing" do
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
        :case,
        :video_hearing_requested,
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
    let(:room_label) { HearingRooms.find!(hearing_day.room)&.label }

    let!(:expected_alert) do
      COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_TO_VIRTUAL"]["TITLE"] % legacy_appeal.veteran.name
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

  shared_examples "scheduling a central hearing" do
    include_context "central_hearings"

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
      find(".cf-form-radio-option", text: "9:00").click
      click_button("Schedule", exact: true)
      click_on "Back to Schedule Veterans"
      expect(page).to have_content("Schedule Veterans")
      click_button("Scheduled Veterans", exact: true)
      expect(VACOLS::Case.where(bfcorlid: "123454787S"))
      click_button("Legacy Veterans Waiting", exact: true)
      expect(page.has_no_content?("123454787S")).to eq(true)
      expect(page).to have_content("There are no schedulable veterans")
      expect(VACOLS::CaseHearing.first.folder_nr).to eq vacols_case.bfkey
    end
  end

  shared_examples "scheduling a video hearing" do
    include_context "video_hearing"

    scenario "Schedule Veteran for video" do
      cache_appeals
      navigate_to_schedule_veteran
      find(".cf-form-radio-option", text: "8:30").click
      click_dropdown(name: "appealHearingLocation", text: "Holdrege, NE (VHA) 0 miles away")
      expect(page).not_to have_content("Could not find hearing locations for this veteran")
      expect(page).not_to have_content("There are no upcoming hearing dates for this regional office.")
      click_dropdown(
        text: "#{hearing_day.scheduled_for.to_formatted_s(:short_date)} (0/#{hearing_day.total_slots}) #{room_label}",
        name: "hearingDate"
      )
      click_button("Schedule", exact: true)
      click_on "Back to Schedule Veterans"
      expect(page).to have_content("Schedule Veterans")
      click_button("Scheduled Veterans", exact: true)
      expect(VACOLS::Case.where(bfcorlid: "123456789S"))
      click_button("Legacy Veterans Waiting", exact: true)
      expect(page.has_no_content?("123456789S")).to eq(true)
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
        expect(page).to have_css(
          ".usa-alert-error",
          text: "Mapping service is temporarily unavailable. Please try again later."
        )
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

      find("label", text: "8:30").click
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
        click_dropdown(
          text: "#{hearing_day.scheduled_for.to_formatted_s(:short_date)} (0/#{hearing_day.total_slots})",
          name: "hearingDate"
        )
        click_dropdown(
          text: "Holdrege, NE (VHA) 0 miles away",
          name: "appealHearingLocation"
        )
        click_dropdown(text: "10:00", name: "optionalHearingTime0")
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
          text: "#{hearing_day.scheduled_for.to_formatted_s(:short_date)} (0/#{hearing_day.total_slots})",
          name: "hearingDate"
        )
        click_dropdown(
          text: "Holdrege, NE (VHA) 0 miles away",
          name: "appealHearingLocation"
        )
        click_dropdown(text: "10:00", name: "optionalHearingTime0")
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
          text: "#{hearing_day.scheduled_for.to_formatted_s(:short_date)} (0/#{hearing_day.total_slots})",
          name: "hearingDate"
        )
        click_dropdown(
          text: "Holdrege, NE (VHA) 0 miles away",
          name: "appealHearingLocation"
        )
        click_dropdown(text: "10:00", name: "optionalHearingTime0")
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
        text: "#{hearing_day.scheduled_for.to_formatted_s(:short_date)} (#{total_slots}/#{total_slots})",
        name: "hearingDate"
      )

      expect(page).to have_content(COPY::SCHEDULE_VETERAN_FULL_HEARING_DAY_TITLE)
      expect(page).to have_content(COPY::SCHEDULE_VETERAN_FULL_HEARING_DAY_MESSAGE_DETAIL)

      click_dropdown(
        text: "Holdrege, NE (VHA) 0 miles away",
        name: "appealHearingLocation"
      )
      click_dropdown(text: "10:00", name: "optionalHearingTime0")
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

  shared_examples "scheduling a virtual hearing" do |fill_in_timezones, ro_key, time|
    scenario "can successfully schedule virtual hearing" do
      navigate_to_schedule_veteran
      expect(page).to have_content("Schedule Veteran for a Hearing")
      click_dropdown(name: "hearingType", text: "Virtual")
      click_dropdown(name: "hearingDate", index: 1)

      expected_time_radio_text = if fill_in_timezones
                                   "#{time} AM Eastern Time (US & Canada)"
                                 else
                                   "#{time} AM Mountain Time (US & Canada) / 10:30 AM Eastern Time (US & Canada)"
                                 end
      find(".cf-form-radio-option", text: expected_time_radio_text).click

      # Fill in appellant details
      click_dropdown(name: "appellantTz", index: 1) if fill_in_timezones
      fill_in "Veteran Email", with: fill_in_veteran_email

      # Fill in POA/Representative details
      click_dropdown(name: "representativeTz", index: 1) if fill_in_timezones
      fill_in "POA/Representative Email", with: fill_in_representative_email

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
    end
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

    context "when changing from Central hearing" do
      include_context "central_hearings"

      before { cache_appeals }

      it_behaves_like "scheduling a virtual hearing", true, "C", "9:00"
    end

    context "when changing from Video hearing" do
      include_context "video_hearing"

      before { cache_appeals }

      it_behaves_like "scheduling a virtual hearing", false, "RO39", "8:30"
    end

    context "withdraw hearing" do
      def schedule_hearing(appeal_link)
        visit appeal_link
        click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
        find(".cf-form-radio-option", text: "8:30").click
        click_dropdown(name: "appealHearingLocation", text: "Holdrege, NE (VHA) 0 miles away")

        room_label = HearingRooms.find!(hearing_day.room)&.label
        click_dropdown(
          text: "#{hearing_day.scheduled_for.to_formatted_s(:short_date)} (0/#{hearing_day.total_slots}) #{room_label}",
          name: "hearingDate"
        )
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
          expect(appeal.tasks.where(type: EvidenceSubmissionWindowTask.name).count).to eq(1)

          if scheduled
            expect(appeal.tasks.where(type: ScheduleHearingTask.name).first.status).to eq(
              Constants.TASK_STATUSES.completed
            )
            expect(appeal.tasks.where(type: AssignHearingDispositionTask.name).first.status).to eq(
              Constants.TASK_STATUSES.cancelled
            )
            expect(appeal.hearings.last.cancelled?).to eq(true)
          else
            expect(appeal.tasks.where(type: ScheduleHearingTask.name).first.status).to eq(
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
            expect(legacy_appeal.tasks.where(type: ScheduleHearingTask.name).first.status).to eq(
              Constants.TASK_STATUSES.completed
            )
            expect(legacy_appeal.tasks.where(type: AssignHearingDispositionTask.name).first.status).to eq(
              Constants.TASK_STATUSES.cancelled
            )
            expect(legacy_appeal.hearings.last.cancelled?).to eq(true)
          else
            expect(legacy_appeal.tasks.where(type: ScheduleHearingTask.name).first.status).to eq(
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
  end

  context "with schedule direct to video/virtual feature disabled" do
    # Ensure the feature flag is disabled before testing
    before do
      FeatureToggle.disable!(:schedule_veteran_virtual_hearing)
    end

    it_behaves_like "scheduling a central hearing"

    it_behaves_like "scheduling a video hearing"

    it_behaves_like "scheduling an AMA hearing"

    it_behaves_like "scheduling a Legacy hearing"

    it_behaves_like "an appeal with a full hearing day"

    it_behaves_like "an appeal where there is an open hearing"
  end
end
