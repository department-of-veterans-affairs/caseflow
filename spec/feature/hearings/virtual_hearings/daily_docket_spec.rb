# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Editing virtual hearing information on daily Docket", :all_dbs do
  before do
    FeatureToggle.enable!(:schedule_virtual_hearings)
  end

  let!(:current_user) { User.authenticate!(css_id: "BVAYELLOW", roles: ["Edit HearSched", "Build HearSched"]) }
  let(:regional_office_key) { "RO59" } # Honolulu, HI
  let(:regional_office_timezone) { RegionalOffice.new(regional_office_key).timezone }
  let!(:hearing) { create(:hearing, :with_tasks, regional_office: regional_office_key, scheduled_time: "9:00AM") }
  let!(:virtual_hearing) { create(:virtual_hearing, :all_emails_sent, status: :active, hearing: hearing) }
  let(:updated_hearing_time) { "11:00 am" }
  let(:updated_virtual_hearing_time) { "11:00 AM Eastern Time (US & Canada)" }
  let(:updated_video_hearing_time) { "11:00 AM Hawaii" }
  let(:expected_regional_office_time) do
    Time
      .parse(updated_hearing_time)
      .strftime("%F %T")
      .in_time_zone(regional_office_timezone) # cast the updated hearing time to the ro timezone
      .strftime("%-l:%M %P %Z")
  end

  # rubocop:disable Metrics/AbcSize
  def check_email_events(hearing, current_user)
    expect(hearing.virtual_hearing.all_emails_sent?).to eq(true)

    events = SentHearingEmailEvent.where(hearing_id: hearing.id)
    expect(events.count).to eq 3
    expect(events.where(sent_by_id: current_user.id).count).to eq 3
    expect(events.where(email_type: "updated_time_confirmation").count).to eq 3
    expect(events.where(email_address: hearing.virtual_hearing.appellant_email).count).to eq 1
    expect(events.sent_to_appellant.count).to eq 1
    expect(events.where(email_address: hearing.virtual_hearing.representative_email).count).to eq 1
    expect(events.where(recipient_role: "representative").count).to eq 1
    expect(events.where(email_address: hearing.virtual_hearing.judge_email).count).to eq 1
    expect(events.where(recipient_role: "judge").count).to eq 1
  end
  # rubocop:enable Metrics/AbcSize

  context "Formerly Video Virtual Hearing" do
    let(:expected_central_office_time) do
      Time
        .parse(updated_hearing_time)
        .strftime("%F %T")
        .in_time_zone(regional_office_timezone) # cast the updated hearing time to the ro timezone
        .in_time_zone(HearingTimeService::CENTRAL_OFFICE_TIMEZONE) # convert it to the central office timezone
        .strftime("%-l:%M %P ET") # and render it in the format expected in the modal
    end

    scenario "Virtual hearing time is updated" do
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
      hearing.reload
      expect(page).to have_content("Daily Docket")
      click_dropdown(name: "optionalHearingTime0", text: updated_video_hearing_time)
      expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_CHANGE_HEARING_TIME_TITLE)
      expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_CHANGE_HEARING_TIME_BUTTON)
      expect(page).to have_content("Time: #{expected_central_office_time} / #{expected_regional_office_time}")
      click_button(COPY::VIRTUAL_HEARING_MODAL_CHANGE_HEARING_TIME_BUTTON)

      hearing.reload
      expect(page).to have_no_content(COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % hearing.appeal.veteran.name)
      expect(page).to have_content(
        format(
          COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_HEARING_TIME"]["MESSAGE"],
          recipients: "Veteran, POA / Representative, and VLJ"
        )
      )

      check_email_events(hearing, current_user)
    end
  end

  context "Formerly Central Virtual Hearing" do
    let!(:central_hearing) { create(:hearing, :with_tasks, scheduled_time: "9:00AM") }
    let!(:central_virtual_hearing) do
      create(:virtual_hearing,
             :all_emails_sent,
             :timezones_initialized,
             status: :active,
             hearing: central_hearing)
    end

    let(:expected_central_office_time) do
      Time
        .parse(updated_hearing_time)
        .strftime("%F %T")
        .in_time_zone(HearingTimeService::CENTRAL_OFFICE_TIMEZONE) # convert it to the central office timezone
        .strftime("%-l:%M %p #{ActiveSupport::TimeZone::MAPPING.key(HearingTimeService::CENTRAL_OFFICE_TIMEZONE)}")
    end

    let(:expected_representative_time) do
      # Pacific time
      Time
        .parse(updated_hearing_time)
        .strftime("%F %T")
        .in_time_zone(HearingTimeService::CENTRAL_OFFICE_TIMEZONE) # convert it to the central office timezone
        .in_time_zone(central_virtual_hearing.representative_tz) # convert it to the appellant timezone
        .strftime("%-l:%M %p #{ActiveSupport::TimeZone::MAPPING.key(central_virtual_hearing.representative_tz)}")
    end
    let(:expected_appellant_time) do
      # Mountain time
      Time
        .parse(updated_hearing_time)
        .strftime("%F %T")
        .in_time_zone(HearingTimeService::CENTRAL_OFFICE_TIMEZONE) # convert it to the central office timezone
        .in_time_zone(central_virtual_hearing.appellant_tz) # convert it to the representative timezone
        .strftime("%-l:%M %p #{ActiveSupport::TimeZone::MAPPING.key(central_virtual_hearing.appellant_tz)}")
    end

    scenario "Virtual Hearing time is updated" do
      visit "hearings/schedule/docket/" + central_hearing.hearing_day.id.to_s
      central_hearing.reload
      expect(page).to have_content("Daily Docket")

      # Change the time
      click_dropdown(name: "optionalHearingTime0", text: updated_virtual_hearing_time)

      # Inspect the virtual hearing modal
      expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_CHANGE_HEARING_TIME_TITLE)
      expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_CHANGE_HEARING_TIME_BUTTON)
      expect(page).to have_content("Time: #{expected_central_office_time}")

      # Appellant section
      expect(page).to have_content("Veteran Hearing Time")
      expect(page).to have_text(expected_appellant_time)
      expect(page).to have_content("Veteran Email")
      expect(page).to have_content(virtual_hearing.appellant_email)

      # POA/Representative section
      expect(page).to have_content("POA/Representative Hearing Time")
      expect(page).to have_content(expected_representative_time)
      expect(page).to have_content("POA/Representative Email")
      expect(page).to have_content(virtual_hearing.representative_email)

      # Confirm changes
      click_button(COPY::VIRTUAL_HEARING_MODAL_CHANGE_HEARING_TIME_BUTTON)

      central_hearing.reload
      expect(page).to have_no_content(COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % central_hearing.appeal.veteran.name)
      expect(page).to have_content(
        format(
          COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_HEARING_TIME"]["MESSAGE"],
          recipients: "Veteran, POA / Representative, and VLJ"
        )
      )

      check_email_events(central_hearing, current_user)
    end
  end

  scenario "Virtual hearing time update is cancelled" do
    visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
    hearing.reload
    expect(page).to have_content("Daily Docket")
    click_dropdown(name: "optionalHearingTime0", index: 3)
    click_button("Update-Hearing-Time-button-id-close")
  end

  context "Dropdowns and radio buttons are disabled while async job is running" do
    scenario "async job is not completed" do
      virtual_hearing.update(appellant_email_sent: false)
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
      expect(find(".dropdown-#{hearing.uuid}-disposition")).to have_css(".cf-select__control--is-disabled")
      expect(find(".dropdown-optionalHearingTime0")).to have_css(".cf-select__control--is-disabled")
    end

    scenario "async job is completed" do
      virtual_hearing.update(appellant_email_sent: true)
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
      expect(find(".dropdown-#{hearing.uuid}-disposition")).to have_no_css(".cf-select__control--is-disabled")
      expect(find(".dropdown-optionalHearingTime0")).to have_no_css(".cf-select__control--is-disabled")
    end
  end

  context "Virtual Hearing Link" do
    let(:vlj_virtual_hearing_link) { COPY::VLJ_VIRTUAL_HEARING_LINK_LABEL_FULL }

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
