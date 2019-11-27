# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Editing virtual hearing information on daily Docket", :all_dbs do
  before do
    FeatureToggle.enable!(:schedule_virtual_hearings)
  end

  let!(:current_user) { User.authenticate!(css_id: "BVAYELLOW", roles: ["Edit HearSched", "Build HearSched"]) }
  let!(:hearing) { create(:hearing, :with_tasks, regional_office: "RO06") }
  let!(:virtual_hearing) { create(:virtual_hearing, hearing: hearing) }

  scenario "Virtual hearing time is updated" do
    visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
    hearing.reload
    choose("hearingTime1_other", allow_label_click: true)
    click_dropdown(name: "optionalHearingTime1", index: 2)
    expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_CHANGE_HEARING_TIME_TITLE)
    expect(page).to have_content(COPY::VIRTUAL_HEARING_CHANGE_HEARING_BUTTON)
    click_button(COPY::VIRTUAL_HEARING_CHANGE_HEARING_BUTTON)
    expect(page).to have_content(COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % hearing.appeal.veteran.name)
  end

  scenario "Virtual hearing time update is cancelled" do
    visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
    choose("hearingTime1_other", allow_label_click: true)
    click_dropdown(name: "optionalHearingTime1", index: 3)
    click_button("Change-Hearing-Time-button-id-close")
  end
end
