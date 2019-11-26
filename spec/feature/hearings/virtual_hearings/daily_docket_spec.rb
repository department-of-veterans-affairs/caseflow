# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Editing virtual hearing information on daily Docket", :all_dbs do
  before do
    FeatureToggle.enable!(:schedule_virtual_hearings)
  end

  let!(:current_user) { User.authenticate!(css_id: "BVAYELLOW", roles: ["Edit HearSched", "Build HearSched"]) }
  let!(:hearing) { create(:hearing, :with_tasks, regional_office: "RO06") }
  let!(:virtual_hearing) { create(:virtual_hearing, hearing: hearing) }

  scenario "Virtual Hearing time has been updated" do
    visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
    hearing.reload
    choose("hearingTime1_other", allow_label_click: true)
    click_dropdown(name: "optionalHearingTime1", index: 2)
    expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_CHANGE_HEARING_TIME_TITLE)
    expect(page).to have_content(COPY::VIRTUAL_HEARING_CHANGE_HEARING_BUTTON)
    click_button(COPY::VIRTUAL_HEARING_CHANGE_HEARING_BUTTON)
    expect(page).to have_content(COPY::VIRTUAL_HEARING_USER_ALERTS["EMAILS_UPDATED"]["MESSAGES"]["TO_VETERAN"])

    virtual_hearing.reload
    expect(virtual_hearing.veteran_email).to eq("newEmail@testingEmail.com")
  end

  scenario "Changes to Virtual Hearing have been cancelled" do
    visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
    choose("hearingTime1_other", allow_label_click: true)
    click_dropdown(name: "optionalHearingTime1", index: 3)
    click_button("Change-to-Virtual-Hearing-button-id-close")
  end
end
