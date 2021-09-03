# frozen_string_literal: true

RSpec.feature "List Schedule for VSO", :all_dbs do
  let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["VSO"]) }

  context "Correct buttons are displayed" do
    let!(:hearing) { create(:hearing) }

    scenario "No buttons are visible" do
      visit "hearings/schedule"

      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER_NONBOARD_USER)
      expect(page).to_not have_content("Schedule Veterans")
      expect(page).to_not have_content("Build Schedule")
      expect(page).to_not have_content("Add Hearing Day")
    end
  end

  context "VSO user view" do
    let!(:judge_one) { create(:user, :with_vacols_judge_record, full_name: "Judge One") }
    let!(:judge_two) { create(:user, :with_vacols_judge_record, full_name: "Judge Two") }
    let!(:judge_three) { create(:user, :with_vacols_judge_record, full_name: "Judge Three") }
    let!(:hearing_day_one) { create(:hearing_day, judge: judge_one) }
    let!(:hearing_day_two) { create(:hearing_day, judge: judge_two) }
    let!(:hearing_day_three) { create(:hearing_day, judge: judge_three) }
    let!(:hearing_one) { create(:hearing, :with_tasks, hearing_day: hearing_day_one) }
    let!(:hearing_two) { create(:hearing, :with_tasks, hearing_day: hearing_day_two) }
    let!(:legacy_hearing) { create(:legacy_hearing, case_hearing: create(:case_hearing, vdkey: hearing_day_three.id)) }
    let!(:vso_participant_id) { Fakes::BGSServicePOA::VIETNAM_VETERANS_VSO_PARTICIPANT_ID }
    let!(:vso) { create(:vso, participant_id: vso_participant_id) }
    let!(:track_veteran_task_one) { create(:track_veteran_task, appeal: hearing_one.appeal, assigned_to: vso) }
    let!(:track_veteran_task_two) { create(:track_veteran_task, appeal: legacy_hearing.appeal, assigned_to: vso) }
    let!(:vso_participant_ids) { Fakes::BGSServicePOA.default_vsos_poas }

    before do
      CachedUser.sync_from_vacols
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
end
