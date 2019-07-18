# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.feature "List Schedule", :vacols do
  context "Correct buttons are displayed based on permissions" do
    let!(:hearing) { create(:hearing) }

    context "Build hearing schedule permissions" do
      let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"]) }

      scenario "All buttons are visible" do
        visit "hearings/schedule"

        expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
        expect(page).to have_content("Schedule Veterans")
        expect(page).to have_content("Build Schedule")
        expect(page).to have_content("Add Hearing Date")
      end
    end

    context "System Admin permissions" do
      let!(:current_user) { User.authenticate!(roles: ["System Admin"]) }
      let!(:hearing_day) { create(:hearing_day) }

      scenario "Correct days are displayed" do
        visit "hearings/schedule"

        expect(page).to have_content(Hearing::HEARING_TYPES[HearingDay.first.request_type.to_sym])
      end

      scenario "All buttons are visible" do
        visit "hearings/schedule"

        expect(page).to have_content(COPY::HEARING_SCHEDULE_JUDGE_DEFAULT_VIEW_PAGE_HEADER)
        expect(page).to have_content("Schedule Veterans")
        expect(page).to have_content("Build Schedule")
        expect(page).to have_content("Add Hearing Date")
      end
    end

    context "Edit hearing schedule permissions" do
      let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Edit HearSched"]) }

      scenario "Only schedule veterans is available" do
        visit "hearings/schedule"

        expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
        expect(page).to have_content("Schedule Veterans")
        expect(page).to_not have_content("Build Schedule")
        expect(page).to_not have_content("Add Hearing Date")
      end
    end

    context "View hearing schedule permissions" do
      let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["RO ViewHearSched"]) }

      scenario "No buttons are visible" do
        visit "hearings/schedule"

        expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER_NONBOARD_USER)
        expect(page).to_not have_content("Schedule Veterans")
        expect(page).to_not have_content("Build Schedule")
        expect(page).to_not have_content("Add Hearing Date")
      end
    end

    context "VSO permissions" do
      let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["VSO"]) }

      scenario "No buttons are visible" do
        visit "hearings/schedule"

        expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER_NONBOARD_USER)
        expect(page).to_not have_content("Schedule Veterans")
        expect(page).to_not have_content("Build Schedule")
        expect(page).to_not have_content("Add Hearing Date")
      end
    end

    context "Judge permissions" do
      let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Hearing Prep"]) }

      scenario "No buttons are visible" do
        visit "hearings/schedule"

        expect(page).to have_content(COPY::HEARING_SCHEDULE_JUDGE_DEFAULT_VIEW_PAGE_HEADER)
        expect(page).to_not have_content("Schedule Veterans")
        expect(page).to_not have_content("Build Schedule")
        expect(page).to_not have_content("Add Hearing Date")
      end
    end
  end

  context "Judge view" do
    let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Hearing Prep"]) }

    context "No hearing day or hearings assigned to judge" do
      let!(:hearing_day) { create(:hearing_day) }

      scenario "Correct hearing days are displayed" do
        visit "hearings/schedule"

        expect(page).to_not have_content(Hearing::HEARING_TYPES[HearingDay.first.request_type.to_sym])
      end
    end

    context "Hearing day assigned to judge" do
      let!(:hearing_day) { create(:hearing_day, judge: current_user) }

      scenario "Correct hearing days are displayed" do
        visit "hearings/schedule"
        expect(page).to have_content(Hearing::HEARING_TYPES[HearingDay.first.request_type.to_sym])
      end
    end

    context "Hearing day assigned to different judge with one legacy hearing assigned to judge" do
      let!(:hearing_day) { create(:hearing_day) }
      let!(:vacols_staff) { create(:staff, user: current_user) }
      let!(:case_hearing) { create(:case_hearing, vdkey: hearing_day.id, board_member: vacols_staff.sattyid) }

      scenario "Correct hearing days are displayed" do
        visit "hearings/schedule"

        expect(page).to have_content(Hearing::HEARING_TYPES[HearingDay.first.request_type.to_sym])
      end
    end

    context "Hearing day assigned to different judge with one AMA hearing assigned to judge" do
      let!(:hearing_day) { create(:hearing_day) }
      let!(:hearing) { create(:hearing, :with_tasks, hearing_day: hearing_day) }

      scenario "Correct hearing days are displayed" do
        hearing.update!(judge: current_user)
        visit "hearings/schedule"

        expect(page).to have_content(Hearing::HEARING_TYPES[HearingDay.first.request_type.to_sym])
      end
    end

    context "Many hearing days assigned to judge and not assigned to judge" do
      let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Hearing Prep"]) }

      before do
        5.times do
          create(:hearing, :with_tasks, judge: current_user)
        end

        5.times do
          create(:hearing, :with_tasks)
        end
      end

      scenario "Can switch to tab to see all hearing days" do
        visit "hearings/schedule"

        page.should have_css(".section-hearings-list tbody tr", count: 5)
        find(".cf-dropdown-trigger", text: "Switch View").click
        find("li", text: "Complete Hearing Schedule").click
        page.should have_css(".section-hearings-list tbody tr", count: 10)
      end
    end
  end

  context "VSO user view" do
    let!(:judge_one) { create(:user, full_name: "Judge One") }
    let!(:judge_two) { create(:user, full_name: "Judge Two") }
    let!(:judge_three) { create(:user, full_name: "Judge Three") }
    let!(:hearing_day_one) { create(:hearing_day, judge: judge_one) }
    let!(:hearing_day_two) { create(:hearing_day, judge: judge_two) }
    let!(:hearing_day_three) { create(:hearing_day, judge: judge_three) }
    let!(:hearing_one) { create(:hearing, :with_tasks, hearing_day: hearing_day_one) }
    let!(:hearing_two) { create(:hearing, :with_tasks, hearing_day: hearing_day_two) }
    let!(:legacy_hearing) { create(:legacy_hearing, case_hearing: create(:case_hearing, vdkey: hearing_day_three.id)) }
    let!(:vso_participant_id) { "789" }
    let!(:vso) { create(:vso, participant_id: vso_participant_id) }
    let!(:current_user) { User.authenticate!(css_id: "VSO_USER", roles: ["VSO"]) }
    let!(:track_veteran_task_one) { create(:track_veteran_task, appeal: hearing_one.appeal, assigned_to: vso) }
    let!(:track_veteran_task_two) { create(:track_veteran_task, appeal: legacy_hearing.appeal, assigned_to: vso) }
    let!(:vso_participant_ids) do
      [
        {
          legacy_poa_cd: "070",
          nm: "VIETNAM VETERANS OF AMERICA",
          org_type_nm: "POA National Organization",
          ptcpnt_id: vso_participant_id
        }
      ]
    end

    before do
      stub_const("BGSService", ExternalApi::BGSService)
      RequestStore[:current_user] = current_user

      allow_any_instance_of(BGS::SecurityWebService).to receive(:find_participant_id)
        .with(css_id: current_user.css_id, station_id: current_user.station_id).and_return(vso_participant_id)
      allow_any_instance_of(BGS::OrgWebService).to receive(:find_poas_by_ptcpnt_id)
        .with(vso_participant_id).and_return(vso_participant_ids)
    end

    scenario "Only hearing days with VSO assigned hearings are displayed" do
      visit "hearings/schedule"
      expect(page).to have_content("One, Judge")
      expect(page).to_not have_content("Two, Judge")
      expect(page).to have_content("Three, Judge")
    end
  end

  context "Hearing prep deprecation" do
    let!(:current_user) { User.authenticate!(roles: ["Hearing Prep"]) }

    scenario "Upcoming docket days redirects to hearing schedule" do
      visit "/hearings/dockets"
      expect(page.current_path).to eq("/hearings/schedule")
    end
  end
end
