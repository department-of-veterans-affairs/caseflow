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

  context "ama appeal" do
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

    scenario "and reschedule" do
      visit "/queue/appeals/#{appeal.external_id}"

      click_dropdown(text: Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h[:label])
      find("label", text: "Reschedule immediately").click
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
      expect(HearingTask.count).to eq 2
    end

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
          "Successfully sent Bob Smith's case to a Hearings Branch administrator for review."
        )
      end
    end
  end

  context "legacy appeal" do
    let!(:legacy_hearing) do
      create(:legacy_hearing, :with_tasks, regional_office: "RO39", hearing_day: hearing_day_earlier)
    end

    scenario "and reschedule on the same day" do
      visit "/queue/appeals/#{legacy_hearing.appeal.external_id}"

      click_dropdown(text: Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h[:label])
      find("label", text: "Reschedule immediately").click
      click_dropdown(name: "regionalOffice", text: "Denver, CO")
      expect(page).to_not have_content("Finding hearing locations", wait: 30)
      click_dropdown(name: "appealHearingLocation", index: 0)
      click_dropdown(name: "hearingDate", index: 1)
      find(".cf-form-radio-option", text: "8:30 am").click
      click_button("Submit")

      expect(page).to have_content("You have successfully assigned")
      expect(LegacyHearing.second.hearing_day.id).to eq hearing_day_earlier.id
      expect(LegacyHearing.first.disposition).to eq "postponed"
      expect(HearingTask.first.hearing.id).to eq legacy_hearing.id
      expect(HearingTask.second.hearing.id).to eq LegacyHearing.second.id
    end
  end
end
