# frozen_string_literal: true

RSpec.feature "Postpone hearing" do
  let!(:current_user) do
    user = create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"])
    HearingsManagement.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let!(:hearing_day) do
    create(
      :hearing_day,
      request_type: HearingDay::REQUEST_TYPES[:video],
      scheduled_for: Time.zone.today + 160.days,
      regional_office: "RO39"
    )
  end

  let!(:hearing_day_earlier) do
    create(
      :hearing_day,
      request_type: HearingDay::REQUEST_TYPES[:video],
      scheduled_for: Time.zone.today + 159.days,
      regional_office: "RO39"
    )
  end

  shared_context "legacy_appeal" do
    let!(:legacy_hearing) do
      create(:legacy_hearing, :with_tasks, regional_office: "RO39", hearing_day: hearing_day_earlier)
    end
  end

  shared_context "ama_appeal" do
    let!(:appeal) do
      create(
        :appeal,
        docket_type: Constants.AMA_DOCKETS.hearing,
        closest_regional_office: "RO39",
        veteran: create(:veteran)
      )
    end
    let!(:hearing) { create(:hearing, appeal: appeal, hearing_day: hearing_day) }
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

  shared_examples "an AMA appeal" do
    scenario "and schedule later with admin action" do
      visit "/queue/appeals/#{appeal.external_id}"

      click_dropdown(text: Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h[:label])
      find("label", text: "Apply admin action").click
      click_dropdown(name: "postponementReason", index: 0)
      fill_in "adminActionInstructions", with: "Test instructions."
      click_button("Submit")

      expect(page).to have_content("was successfully added back to the schedule veteran list.")
      expect(Hearing.first.disposition).to eq "postponed"
      expect(HearingTask.count).to eq 2
      expect(ScheduleHearingTask.count).to eq 1
      expect(HearingAdminActionContestedClaimantTask.where(parent: ScheduleHearingTask.first).count).to eq 1
    end

    scenario "and schedule later" do
      visit "/queue/appeals/#{appeal.external_id}"

      click_dropdown(text: Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h[:label])
      find("label", text: "Send to Schedule Veteran list").click
      click_button("Submit")

      expect(page).to have_content("was successfully added back to the schedule veteran list.")
      expect(Hearing.count).to eq 1
      expect(Hearing.first.disposition).to eq "postponed"
      expect(HearingTask.count).to eq 2
      expect(ScheduleHearingTask.count).to eq 1
    end

    scenario "then change to held" do
      step "postpone and send back to scheduling" do
        visit "/queue/appeals/#{appeal.external_id}"

        click_dropdown(text: Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h[:label])
        find("label", text: "Send to Schedule Veteran list").click
        click_button("Submit")

        expect(page).to have_content("was successfully added back to the schedule veteran list.")
      end

      step "change disposition to held" do
        visit "/queue/appeals/#{appeal.external_id}"

        click_dropdown(
          text: Constants.TASK_ACTIONS.CREATE_CHANGE_PREVIOUS_HEARING_DISPOSITION_TASK.to_h[:label]
        )
        fill_in "Notes", with: "Reason for changing."
        click_button("Submit")

        expect(page).to have_content(
          /Successfully sent Bob Smith.*'s case to a Hearings Branch administrator for review./
        )
      end
    end
  end

  context "with schedule direct to video/virtual feature disabled" do
    # Ensure the feature flag is disabled before testing
    before do
      FeatureToggle.disable!(:schedule_veteran_virtual_hearing)
    end

    # Test the reschedule scenario
    context "for AMA appeals" do
      include_context "ama_appeal"

      # Run the AMA scenarios
      it_behaves_like "an AMA appeal"

      scenario "when rescheduling" do
        visit "/queue/appeals/#{appeal.external_id}"

        click_dropdown(text: Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h[:label])
        find("label", text: "Reschedule immediately").click
        expect(page).to_not have_content("Schedule Veteran for a Hearing")
        click_dropdown(name: "regionalOffice", text: "Denver, CO")
        expect(page).to_not have_content("Finding hearing locations", wait: 30)
        click_dropdown(name: "appealHearingLocation", index: 0)
        click_dropdown(name: "hearingDate", index: 1)
        find(".cf-form-radio-option", text: "8:30 am").click
        click_button("Submit")

        expect(page).to have_content("You have successfully assigned")
        expect(Hearing.where(hearing_day: hearing_day_earlier).count).to eq 1
        expect(Hearing.find_by(hearing_day: hearing_day_earlier).hearing_location.facility_id).to eq "vba_339"
        expect(Hearing.first.disposition).to eq "postponed"
        expect(Hearing.second.disposition).to be_nil
        expect(Hearing.second.uuid).to_not eq Hearing.first.uuid
        expect(HearingTask.count).to eq 2
      end
    end

    context "for a Legacy appeal" do
      include_context "legacy_appeal"

      scenario "when rescheduling on the same day" do
        visit "/queue/appeals/#{legacy_hearing.appeal.external_id}"

        click_dropdown(text: Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h[:label])
        find("label", text: "Reschedule immediately").click
        expect(page).to_not have_content("Schedule Veteran for a Hearing")
        click_dropdown(name: "regionalOffice", text: "Denver, CO")
        expect(page).to_not have_content("Finding hearing locations", wait: 30)
        click_dropdown(name: "appealHearingLocation", index: 0)
        click_dropdown(name: "hearingDate", index: 1)
        find(".cf-form-radio-option", text: "8:30 am").click
        click_button("Submit")

        expect(page).to have_content("You have successfully assigned")
        expect(LegacyHearing.second.hearing_day.id).to eq hearing_day_earlier.id
        expect(LegacyHearing.first.disposition).to eq "postponed"
        expect(LegacyHearing.second.disposition).to be_nil
        expect(LegacyHearing.second.vacols_id).to_not eq LegacyHearing.first.vacols_id
        expect(HearingTask.first.hearing.id).to eq legacy_hearing.id
        expect(HearingTask.second.hearing.id).to eq LegacyHearing.second.id
      end
    end
  end

  context "with schedule direct to video/virtual feature enabled" do
    # Ensure the feature flag is enabled before testing
    before do
      FeatureToggle.enable!(:schedule_veteran_virtual_hearing)
    end

    context "for AMA appeals" do
      # Include the AMA appeal
      include_context "ama_appeal"

      let(:fill_in_veteran_email) { "vet@testingEmail.com" }
      let(:fill_in_representative_email) { "email@testingEmail.com" }
      let!(:expected_alert) do
        COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_TO_VIRTUAL"]["TITLE"] % appeal.veteran.name
      end

      # Run the AMA scenarios
      it_behaves_like "an AMA appeal"

      scenario "when rescheduling to Video hearing" do
        visit "/queue/appeals/#{appeal.external_id}"

        click_dropdown(text: Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h[:label])
        find("label", text: "Reschedule immediately").click
        click_button("Submit")

        expect(page).to have_content("Schedule Veteran for a Hearing")
        click_dropdown(name: "regionalOffice", text: "Denver, CO")
        expect(page).to_not have_content("Finding hearing locations", wait: 30)
        click_dropdown(name: "appealHearingLocation", index: 0)
        click_dropdown(name: "hearingDate", index: 1)
        find(
          ".cf-form-radio-option",
          text: "8:30 AM Mountain Time (US & Canada) / 10:30 AM Eastern Time (US & Canada)"
        ).click
        click_button("Schedule")

        expect(page).to have_content("You have successfully assigned")
        expect(Hearing.where(hearing_day: hearing_day_earlier).count).to eq 1
        expect(Hearing.find_by(hearing_day: hearing_day_earlier).hearing_location.facility_id).to eq "vba_339"
        expect(Hearing.first.disposition).to eq "postponed"
        expect(HearingTask.count).to eq 2
      end

      scenario "when rescheduling to Virtual hearing" do
        visit "/queue/appeals/#{appeal.external_id}"

        click_dropdown(text: Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h[:label])
        find("label", text: "Reschedule immediately").click
        click_button("Submit")

        expect(page).to have_content("Schedule Veteran for a Hearing")
        click_dropdown(name: "hearingType", text: "Virtual")
        click_dropdown(name: "hearingDate", index: 1)
        find(
          ".cf-form-radio-option",
          text: "8:30 AM Mountain Time (US & Canada) / 10:30 AM Eastern Time (US & Canada)"
        ).click

        # Fill in appellant details
        fill_in "Veteran Email", with: fill_in_veteran_email

        # Fill in POA/Representative details
        fill_in "POA/Representative Email", with: fill_in_representative_email

        click_button("Schedule")

        expect(page).to have_content(expected_alert)
        expect(VirtualHearing.count).to eq(1)
        expect(Hearing.where(hearing_day: hearing_day_earlier).count).to eq 1

        # Retrieve the newly created hearing
        new_hearing = Hearing.find_by(hearing_day: hearing_day_earlier)

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
        expect(Hearing.first.disposition).to eq "postponed"
        expect(HearingTask.count).to eq 2
      end
    end

    context "for a Legacy appeal" do
      include_context "legacy_appeal"

      scenario "when rescheduling on the same day" do
        visit "/queue/appeals/#{legacy_hearing.appeal.external_id}"

        click_dropdown(text: Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h[:label])
        find("label", text: "Reschedule immediately").click
        click_button("Submit")

        expect(page).to have_content("Schedule Veteran for a Hearing")
        click_dropdown(name: "regionalOffice", text: "Denver, CO")
        expect(page).to_not have_content("Finding hearing locations", wait: 30)
        click_dropdown(name: "appealHearingLocation", index: 0)
        click_dropdown(name: "hearingDate", index: 1)
        find(
          ".cf-form-radio-option",
          text: "8:30 AM Mountain Time (US & Canada) / 10:30 AM Eastern Time (US & Canada)"
        ).click
        click_button("Schedule")

        expect(page).to have_content("You have successfully assigned")
        expect(LegacyHearing.second.hearing_day.id).to eq hearing_day_earlier.id
        expect(LegacyHearing.first.disposition).to eq "postponed"
        expect(LegacyHearing.second.disposition).to be_nil
        expect(LegacyHearing.second.vacols_id).to_not eq LegacyHearing.first.vacols_id
        expect(HearingTask.first.hearing.id).to eq legacy_hearing.id
        expect(HearingTask.second.hearing.id).to eq LegacyHearing.second.id
      end
    end
  end
end
