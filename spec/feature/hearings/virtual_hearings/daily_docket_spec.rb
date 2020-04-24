# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Editing virtual hearing information on daily Docket", :all_dbs do
  before do
    FeatureToggle.enable!(:schedule_virtual_hearings)
  end

  let!(:current_user) { User.authenticate!(css_id: "BVAYELLOW", roles: ["Edit HearSched", "Build HearSched"]) }
  let!(:hearing) { create(:hearing, :with_tasks, regional_office: "RO06", scheduled_time: "9:00AM") }
  let!(:virtual_hearing) { create(:virtual_hearing, :all_emails_sent, status: :active, hearing: hearing) }

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
    expect(page).to have_content(COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_HEARING_TIME"]["MESSAGE"])
    expect(hearing.virtual_hearing.all_emails_sent?).to eq(true)

    events = SentHearingEmailEvent.where(hearing_id: hearing.id)
    expect(events.count).to eq 3
    expect(events.where(sent_by_id: current_user.id).count).to eq 3
    expect(events.where(email_type: "updated_time_confirmation").count).to eq 3
    expect(events.where(email_address: hearing.virtual_hearing.veteran_email).count).to eq 1
    expect(events.where(recipient_role: "veteran").count).to eq 1
    expect(events.where(email_address: hearing.virtual_hearing.representative_email).count).to eq 1
    expect(events.where(recipient_role: "representative").count).to eq 1
    expect(events.where(email_address: hearing.virtual_hearing.judge_email).count).to eq 1
    expect(events.where(recipient_role: "judge").count).to eq 1
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

  context "Virtual Hearing Link" do
    let(:vlj_virtual_hearing_link) { COPY::VLJ_VIRTUAL_HEARING_LINK_LABEL }

    context "Hearing Coordinator view" do
      scenario "User has the host link" do
        visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s

        expect(page).to have_content(vlj_virtual_hearing_link)
        expect(page).to have_xpath "//a[contains(@href,'role=host')]"
      end
    end
    context "VLJ view" do
      let(:current_user) { User.authenticate!(css_id: hearing.judge.css_id, roles: ["Hearing Prep"]) }

      scenario "User has the host link" do
        visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s

        expect(page).to have_content(vlj_virtual_hearing_link)
        expect(page).to have_xpath "//a[contains(@href,'role=host')]"
      end
    end
  end
end
