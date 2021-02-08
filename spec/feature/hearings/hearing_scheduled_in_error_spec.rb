# frozen_string_literal: true

RSpec.feature "Remove hearing scheduled in error" do
  before { FeatureToggle.enable!(:schedule_veteran_virtual_hearing) }
  after { FeatureToggle.disable!(:schedule_veteran_virtual_hearing) }

  let!(:current_user) do
    user = create(:user, css_id: "BVASYELLOW", roles: ["Edit HearSched"])
    HearingsManagement.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let(:regional_office) { "RO39" } # Denver
  let(:hearing_notes) { "Test Notes" }
  let(:fill_in_notes) { "New notes" }

  shared_context "hearing day" do
    let!(:video_hearing_day) do
      create(
        :hearing_day,
        request_type: HearingDay::REQUEST_TYPES[:video],
        scheduled_for: Time.zone.today + 160.days,
        regional_office: regional_office
      )
    end
  end

  shared_context "hearing subtree" do
    let!(:root_task) { create(:root_task, appeal: appeal) }
    let!(:hearing_task) { create(:hearing_task, parent: root_task) }
    let!(:hearing_task_association) do
      create(
        :hearing_task_association,
        hearing: hearing,
        hearing_task: hearing_task
      )
    end
    let!(:assign_hearing_disposition_task) do
      create(:assign_hearing_disposition_task, parent: hearing_task)
    end
  end

  shared_context "Modal displays correctly" do
    scenario "Clicking on action 'Remove Hearing Scheduled in Error' opens correct modal" do
      visit "/queue/appeals/#{appeal.external_id}"

      click_dropdown(text: Constants.TASK_ACTIONS.REMOVE_HEARING_SCHEDULED_IN_ERROR.to_h[:label])
      expect(page).to have_content(COPY::HEARING_SCHEDULED_IN_ERROR_MODAL_TITLE)
      expect(page).to have_content(COPY::HEARING_SCHEDULED_IN_ERROR_MODAL_INTRO)
      expect(page).to have_content(COPY::RESCHEDULE_IMMEDIATELY_DISPLAY_TEXT)
      expect(page).to have_content(COPY::SCHEDULE_LATER_DISPLAY_TEXT)
      expect(page).to have_field("Notes")
      expect(page).to have_content(hearing_notes)
    end
  end

  def fill_preliminary_reschedule_form(virtual = false)
    visit "/queue/appeals/#{appeal.external_id}"

    click_dropdown(text: Constants.TASK_ACTIONS.REMOVE_HEARING_SCHEDULED_IN_ERROR.to_h[:label])
    find("label", text: COPY::RESCHEDULE_IMMEDIATELY_DISPLAY_TEXT).click
    fill_in "Notes", with: fill_in_notes
    click_button("Submit")

    expect(page).to have_content("Schedule Veteran for a Hearing")
    if virtual
      click_dropdown(name: "hearingType", text: "Virtual")
    else
      click_dropdown(name: "regionalOffice", text: "Denver, CO")
      expect(page).to_not have_content("Finding hearing locations", wait: 30)
      click_dropdown(name: "appealHearingLocation", index: 0)
    end
    click_dropdown(name: "hearingDate", index: 1)
    find(
      ".cf-form-radio-option",
      text: "8:30 AM Mountain Time (US & Canada) / 10:30 AM Eastern Time (US & Canada)"
    ).click
  end

  shared_context "Reschedule Immediately" do
    let(:fill_in_veteran_email) { "vet@testingEmail.com" }
    let(:fill_in_representative_email) { "email@testingEmail.com" }
    let(:expected_alert) do
      COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_TO_VIRTUAL"]["TITLE"] % appeal.veteran&.name
    end

    scenario "Reschedule to a Video hearing" do
      fill_preliminary_reschedule_form
      click_button("Schedule")

      expect(page).to have_content("You have successfully assigned")
      expect(hearing_class.last.hearing_day_id).to eq(video_hearing_day.id)
      expect(hearing_class.where(hearing_day_id: video_hearing_day.id).reload.count).to eq 2
      expect(hearing.reload.disposition).to eq Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error
      expect(hearing.reload.notes).to eq(fill_in_notes)
      expect(hearing_class.count).to eq 2
    end

    context "Reschedule to a Virtual hearing" do
      scenario "Reschedule to a Virtual hearing without error" do
        fill_preliminary_reschedule_form(true)

        # Fill in appellant details
        fill_in "Veteran Email", with: fill_in_veteran_email

        # Fill in POA/Representative details
        fill_in "POA/Representative Email", with: fill_in_representative_email

        click_button("Schedule")

        expect(page).to have_content(expected_alert)
        expect(VirtualHearing.count).to eq(1)

        expect(hearing_class.count).to eq 2
        expect(hearing_class.last.hearing_day_id).to eq(video_hearing_day.id)
        expect(hearing_class.where(hearing_day_id: video_hearing_day.id).reload.count).to eq 2

        # Retrieve the newly created hearing
        new_hearing = hearing_class.where(hearing_day_id: video_hearing_day.id).last

        # Test the hearing was created correctly with the virtual hearing
        expect(new_hearing.hearing_location).to eq nil
        expect(new_hearing.virtual_hearing).to eq VirtualHearing.first

        # Test the emails were sent
        events = SentHearingEmailEvent.where(hearing_id: new_hearing.id)
        expect(events.count).to eq 2
        expect(events.where(sent_by_id: current_user.id).count).to eq 2
        expect(events.where(email_type: "confirmation").count).to eq 2
        expect(events.where(email_address: fill_in_veteran_email).count).to eq 1
        expect(events.sent_to_appellant.count).to eq 1
        expect(events.where(email_address: fill_in_representative_email).count).to eq 1
        expect(events.where(recipient_role: "representative").count).to eq 1

        # Test the hearing was updated correctly
        expect(hearing.reload.disposition).to eq Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error
        expect(hearing.reload.notes).to eq fill_in_notes
      end

      scenario "Reschedule to a Virtual hearing with error" do
        fill_preliminary_reschedule_form(true)

        fill_in "Veteran Email", with: "invalid email"
        click_button("Schedule")
        expect(page).to have_content("Veteran email does not appear to be a valid e-mail address")
        expect(hearing_class.where(hearing_day_id: video_hearing_day.id).reload.count).to eq 1
        expect(hearing.reload.disposition).to eq nil
        expect(hearing.reload.notes).to eq(hearing_notes)
        expect(hearing_class.count).to eq 1
      end
    end
  end

  shared_context "Send to Veterans List" do
    scenario "Schedule Later" do
      visit "/queue/appeals/#{appeal.external_id}"

      click_dropdown(text: Constants.TASK_ACTIONS.REMOVE_HEARING_SCHEDULED_IN_ERROR.to_h[:label])
      find("label", text: COPY::SCHEDULE_LATER_DISPLAY_TEXT).click
      fill_in "Notes", with: fill_in_notes
      click_button("Submit")

      expect(page).to have_content("was successfully added back to the schedule veteran list.")
      expect(hearing_class.count).to eq 1
      expect(hearing.reload.disposition).to eq Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error
      expect(hearing.reload.notes).to eq(fill_in_notes)
      expect(HearingTask.count).to eq 2
      expect(ScheduleHearingTask.count).to eq 1
    end
  end

  context "AMA appeal" do
    let(:appeal) do
      create(
        :appeal,
        docket_type: Constants.AMA_DOCKETS.hearing,
        closest_regional_office: regional_office
      )
    end

    let!(:hearing) do
      create(:hearing, appeal: appeal, hearing_day: video_hearing_day, notes: hearing_notes)
    end

    let(:hearing_class) { Hearing.name.constantize }

    include_context "hearing day"
    include_context "hearing subtree"
    include_context "Modal displays correctly"
    include_context "Reschedule Immediately"
    include_context "Send to Veterans List"
  end

  context "Legacy Appeal" do
    let(:vacols_case) { create(:case) }
    let(:appeal) do
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: vacols_case,
        closest_regional_office: regional_office
      )
    end
    let!(:hearing) do
      create(
        :legacy_hearing,
        :for_vacols_case,
        appeal: appeal,
        regional_office: regional_office,
        hearing_day: video_hearing_day,
        notes: hearing_notes
      )
    end

    let(:hearing_class) { LegacyHearing.name.constantize }

    include_context "hearing day"
    include_context "hearing subtree"
    include_context "Modal displays correctly"
    include_context "Reschedule Immediately"
    include_context "Send to Veterans List"
  end
end
