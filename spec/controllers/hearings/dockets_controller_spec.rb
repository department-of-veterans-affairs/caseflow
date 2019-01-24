RSpec.describe Hearings::DocketsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep"]) }
  let!(:staff) {create(:staff, user: user)}
  let!(:case_hearing) {create(:case_hearing, user: user, hearing_date: Time.zone.today, board_member: staff.sattyid)}
  let!(:legacy_hearing) { create(:legacy_hearing, case_hearing: case_hearing) }
  let!(:hearing_day) {create(:hearing_day, scheduled_for: Time.zone.today + 1)}
  let!(:hearing) { create(:hearing, hearing_day: hearing_day, judge_id: user.id) }

  describe "SHOW Daily Docket" do
    it "returns legacy data with success" do
      get :show, params: { docket_date: legacy_hearing.scheduled_for }, format: "json"
      response_hearing = JSON.parse(response.body)
      expect(response.status).to eq 200
      expect(response_hearing["hearingDay"]["requestType"]).to eq nil
      expect(response_hearing["hearingDay"]["room"]).to eq nil
      expect(response_hearing["dailyDocket"].length).to eq 1
    end

    it "returns data with success" do
      get :show, params: { docket_date: hearing_day.scheduled_for }, format: "json"
      response_hearing = JSON.parse(response.body)
      expect(response.status).to eq 200
      expect(response_hearing["hearingDay"]["requestType"]).to eq "Central"
      expect(response_hearing["hearingDay"]["room"]).to eq "2"
      expect(response_hearing["dailyDocket"].length).to eq 1
    end

    it "should fail with 404 error message" do
      get :show, params: { docket_date: "2019-01-01" }, format: "json"
      expect(response.status).to eq 404
      body = response.body
      expect(body).to eq "{\"errors\":[\"Response not found\"]}"
    end
  end
end
