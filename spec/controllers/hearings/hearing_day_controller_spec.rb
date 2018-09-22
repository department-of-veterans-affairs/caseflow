RSpec.describe Hearings::HearingDayController, type: :controller do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  let!(:user) { User.authenticate!(roles: ["Build HearSched"]) }
  let!(:staff) { create(:staff, stafkey: "RO04", stc2: 2, stc3: 3, stc4: 4) }
  let!(:hearing) do
    create(:case_hearing,
           hearing_type: "C",
           hearing_date: Date.new(2018, 4, 2),
           folder_nr: "VIDEO RO04")
  end

  context "index_with_hearings" do
    it "returns all hearing days with hearings and slots" do
      get :index_with_hearings, params: { regional_office: "RO04" }, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["hearing_days"].size).to eq 1
      expect(response_body["hearing_days"][0]["total_slots"]).to eq 4
    end
  end
end
