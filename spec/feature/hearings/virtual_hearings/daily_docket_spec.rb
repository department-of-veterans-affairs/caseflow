# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Editing virtual hearing information on daily Docket", :all_dbs do
  let!(:current_user) { User.authenticate!(css_id: "BVAYELLOW", roles: ["Edit HearSched", "Build HearSched"]) }
  let(:regional_office_key) { "RO59" } # Honolulu, HI
  let(:regional_office_timezone) { RegionalOffice.new(regional_office_key).timezone }
  let!(:hearing) { create(:hearing, :with_tasks, regional_office: regional_office_key, scheduled_time: "9:00AM") }
  let!(:virtual_hearing) do
    create(:virtual_hearing, :all_emails_sent, :initialized, status: :active, hearing: hearing)
  end
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
      time_str = "#{updated_hearing_time} #{hearing.hearing_day.scheduled_for} America/New_York"
      tz_abbr = Time.zone.parse(time_str).dst? ? "ET" : "EST"

      Time
        .parse(updated_hearing_time)
        .strftime("%F %T")
        .in_time_zone(regional_office_timezone) # cast the updated hearing time to the ro timezone
        .in_time_zone(HearingTimeService::CENTRAL_OFFICE_TIMEZONE) # convert it to the central office timezone
        .strftime("%-l:%M %p #{tz_abbr}") # and render it in the format expected in the modal
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
             :initialized,
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

  context "Virtual Hearing Link" do
    let(:vlj_virtual_hearing_link) { COPY::VLJ_VIRTUAL_HEARING_LINK_LABEL_FULL }

    context "Hearing Coordinator view" do
      scenario "User has the host link" do
        visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s

        expect(page).to have_content(vlj_virtual_hearing_link)
      end
    end
    context "VLJ view" do
      let(:current_user) { User.authenticate!(css_id: hearing.judge.css_id, roles: ["Hearing Prep"]) }

      scenario "User has the host link" do
        visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s

        expect(page).to have_content(vlj_virtual_hearing_link)
      end
    end
  end

  context "Updating a hearing's time" do
    shared_examples "The hearing time is updated correctly" do
      scenario do
        visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
        click_dropdown(name: "optionalHearingTime0", text: hearing_time_selection_string)
        click_button("Update Hearing Time")

        expect(page).to have_content(expected_post_update_time)
      end
    end

    context "Legacy Hearing" do
      let(:case_hearing) { create(:case_hearing) }
      let(:initial_hearing) { create(:legacy_hearing, case_hearing: case_hearing) }

      # Ensure that the times are always in standard time.
      before { initial_hearing.hearing_day.update!(scheduled_for: "2024-11-11") }

      context "With a pre-existing scheduled_in_timezone value" do
        let(:hearing_time_selection_string) { "10:00 AM Central Time (US & Canada)" }
        let(:hearing) { initial_hearing.tap { _1.update!(scheduled_in_timezone: "America/Chicago") } }
        let(:expected_post_update_time) { "10:00 AM CST" }

        before do
          hearing.hearing_day.update!(regional_office: "RO30", request_type: "V", scheduled_for: "2024-11-11")
        end

        include_examples "The hearing time is updated correctly"
      end

      context "Without a pre-existing scheduled_in_timezone value" do
        let(:hearing_time_selection_string) { "3:00 PM Central Time (US & Canada)" }
        let(:hearing) { initial_hearing.tap { _1.update!(scheduled_in_timezone: nil) } }
        let(:expected_post_update_time) { "3:00 PM CST" }

        before do
          hearing.hearing_day.update!(regional_office: "RO30", request_type: "T", scheduled_for: "2024-11-11")
        end

        include_examples "The hearing time is updated correctly"
      end
    end

    context "AMA Hearing" do
      let(:initial_hearing) { create(:hearing) }

      context "With a pre-existing scheduled_datetime value" do
        let(:hearing_time_selection_string) { "12:00 PM Alaska" }
        let(:hearing) { initial_hearing.tap { _1.update!(scheduled_in_timezone: "America/Juneau") } }
        let(:expected_post_update_time) { "12:00 PM #{Time.zone.now.dst? ? 'AKDT' : 'AKST'}" }

        before { hearing.hearing_day.update!(regional_office: "RO63", request_type: "V") }

        include_examples "The hearing time is updated correctly"
      end

      context "Without a pre-existing scheduled_datetime value" do
        let(:hearing_time_selection_string) { "11:00 AM Hawaii" }
        let(:hearing) { initial_hearing.tap { _1.update!(scheduled_in_timezone: nil) } }
        let(:expected_post_update_time) { "11:00 AM HST" }

        before { hearing.hearing_day.update!(regional_office: "RO59", request_type: "V") }

        include_examples "The hearing time is updated correctly"
      end
    end
  end
end
