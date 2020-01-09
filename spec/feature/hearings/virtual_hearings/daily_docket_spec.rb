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
    expect(page).to have_no_content(COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % hearing.appeal.veteran.name)
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

  context "Dropdowns and radio buttons are disabled while async job is running" do
    scenario "async job is not completed" do
      virtual_hearing.update(veteran_email_sent: false)
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
      expect(find(".dropdown-#{hearing.uuid}-disposition")).to have_css(".is-disabled")
      expect(all(".cf-form-radio-option").first).to have_css(".disabled")
      expect(find(".dropdown-optionalHearingTime1")).to have_css(".is-disabled")
    end

    scenario "async job is completed" do
      virtual_hearing.update(veteran_email_sent: true)
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
      expect(find(".dropdown-#{hearing.uuid}-disposition")).to have_no_css(".is-disabled")
      expect(all(".cf-form-radio-option").first).to have_no_css(".disabled")
      expect(find(".dropdown-optionalHearingTime1")).to have_no_css(".is-disabled")
    end
  end
end
