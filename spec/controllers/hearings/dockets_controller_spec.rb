# frozen_string_literal: true

RSpec.describe Hearings::DocketsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep"]) }
  let!(:staff) { create(:staff, user: user) }
  let!(:case_hearing) { create(:case_hearing, user: user, hearing_date: Time.zone.today, board_member: staff.sattyid) }
  let!(:legacy_hearing) { create(:legacy_hearing, case_hearing: case_hearing) }
  let!(:hearing_day) { create(:hearing_day, scheduled_for: Time.zone.today + 1, judge_id: user.id) }
  let!(:expected_hearing_day) do
    {
      requestType: HearingDayMapper.label_for_type(hearing_day.request_type),
      coordinator: hearing_day.bva_poc,
      room: hearing_day.room,
      notes: hearing_day.notes
    }
  end
  let!(:hearing) { create(:hearing, :with_tasks, hearing_day: hearing_day, judge_id: user.id) }

  describe "SHOW Daily Docket" do
    it "returns legacy data with success" do
      get :show, params: { docket_date: legacy_hearing.scheduled_for }, format: "json"
      response_hearing = JSON.parse(response.body)
      expect(response.status).to eq 200
      expect(response_hearing["hearingDay"]).to eq expected_hearing_day.stringify_keys
      expect(response_hearing["dailyDocket"].length).to eq 1
    end

    context "without making a bgs call" do
      before do
        BGSService.instance_methods(false).each do |method_name|
          expect_any_instance_of(BGSService).not_to receive(method_name)
        end
      end

      it "returns data with success without BGS call" do
        get :show, params: { docket_date: hearing_day.scheduled_for }, format: "json"
        response_hearing = JSON.parse(response.body)
        expect(response.status).to eq 200
        expect(response_hearing["hearingDay"]["requestType"]).to eq "Central"
        expect(response_hearing["hearingDay"]["room"]).to eq "2"
        expect(response_hearing["dailyDocket"].length).to eq 1
      end
    end

    it "should fail with 404 error message" do
      get :show, params: { docket_date: "2019-01-01" }, format: "json"
      expect(response.status).to eq 404
      body = response.body
      expect(body).to eq "{\"errors\":[\"Response not found\"]}"
    end
  end
end
