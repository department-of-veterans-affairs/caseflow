# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Editing virtual hearing information on daily Docket", :all_dbs do
  before do
    FeatureToggle.enable!(:schedule_virtual_hearings)
  end

  let!(:current_user) { User.authenticate!(css_id: "BVAYELLOW", roles: ["Edit HearSched", "Build HearSched"]) }
  let!(:hearing) { create(:hearing, :with_tasks, regional_office: "RO06", scheduled_time: "9:00AM") }
  let!(:virtual_hearing) { create(:virtual_hearing, :active, :all_emails_sent, hearing: hearing) }

  scenario "Virtual hearing time is updated" do
    visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
    hearing.reload
    expect(page).to have_content("Daily Docket")
    choose("hearingTime1_other", allow_label_click: true)
    click_dropdown(name: "optionalHearingTime1", index: 2)
    expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_CHANGE_HEARING_TIME_TITLE)
    expect(page).to have_content(COPY::VIRTUAL_HEARING_CHANGE_HEARING_BUTTON)
    click_button(COPY::VIRTUAL_HEARING_CHANGE_HEARING_BUTTON)

    hearing.reload
    expect(page).to have_content(COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % hearing.appeal.veteran.name)
    expect(page).to have_content(COPY::VIRTUAL_HEARING_USER_ALERTS["HEARING_TIME_CHANGED"]["MESSAGE"])
    expect(hearing.virtual_hearing.all_emails_sent?).to eq(true)
  end

  scenario "Virtual hearing time update is cancelled" do
    visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
    hearing.reload
    expect(page).to have_content("Daily Docket")
    choose("hearingTime1_other", allow_label_click: true)
    click_dropdown(name: "optionalHearingTime1", index: 3)
    click_button("Change-Hearing-Time-button-id-close")
  end
end
