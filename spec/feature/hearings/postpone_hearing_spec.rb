# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.feature "Postpone hearing", :all_dbs do
  let!(:current_user) do
    user = create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"])
    OrganizationsUser.add_user_to_organization(user, HearingsManagement.singleton)
    User.authenticate!(user: user)
  end

  let!(:hearings_user) do
    create(:hearings_management)
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
        docket_type: "hearing",
        closest_regional_office: "RO39",
        veteran: create(:veteran)
      )
    end
    let!(:hearing) { FactoryBot.create(:hearing, appeal: appeal, hearing_day: hearing_day) }
    let!(:hearing_task) { create(:hearing_task, parent: RootTask.find_by(appeal: appeal), appeal: appeal) }
    let!(:disposition_task) do
      AssignHearingDispositionTask.create_assign_hearing_disposition_task!(appeal, hearing_task, hearing)
    end

    scenario "and reschedule", skip: "flake https://circleci.com/gh/department-of-veterans-affairs/caseflow/72265" do
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
