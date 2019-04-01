# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Postpone hearing" do
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
      scheduled_for: Time.zone.today + 160,
      regional_office: "RO39"
    )
  end

  let!(:hearing_day_2) do
    create(
      :hearing_day,
      request_type: HearingDay::REQUEST_TYPES[:video],
      scheduled_for: Time.zone.today + 160,
      regional_office: "RO39"
    )
  end

  let!(:appeal) do
    create(
      :appeal,
      :with_tasks,
      docket_type: "hearing",
      closest_regional_office: "RO39",
      veteran: create(:veteran)
    )
  end

  let!(:hearing) { FactoryBot.create(:hearing, appeal: appeal, hearing_day: hearing_day) }
  let!(:hearing_task) { create(:hearing_task, parent: RootTask.find_by(appeal: appeal), appeal: appeal) }
  let!(:disposition_task) { DispositionTask.create_disposition_task!(appeal, hearing_task, hearing) }

  scenario "and reschedule" do
    visit "/queue/appeals/#{appeal.external_id}"

    click_dropdown(text: Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h[:label])
    find("label", text: "Reschedule immediately").click
    click_dropdown(name: "regionalOffice", text: "Denver, CO")
    click_dropdown(name: "appealHearingLocation", index: 0)
    click_dropdown(name: "hearingDate", index: 1)
    find(".cf-form-radio-option", text: "8:30 am").click
    click_button("Submit")

    expect(page).to have_content("You have successfully assigned")
    expect(Hearing.where(hearing_day: hearing_day_2).count).to eq 1
    expect(Hearing.find_by(hearing_day: hearing_day_2).hearing_location.facility_id).to eq "vba_339"
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
