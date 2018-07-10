RSpec.describe Hearings::SchedulePeriodsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Build HearSched"]) }
  let!(:ro_schedule_period) { create(:ro_schedule_period) }
  let!(:judge_schedule_period) { create(:judge_schedule_period) }

  context "index" do
    it "returns all schedule periods" do
      get :index, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["schedule_periods"].size).to eq 2
    end
  end

  context "create" do
    it "creates a new schedule period" do
      id = SchedulePeriod.last.id + 1
      post :create, params: { schedule_period: {
        type: 'RoSchedulePeriod',
        start_date: '2015/10/24',
        end_date: '2016/10/24',
        file_name: 'fakeFileName.xlsx'
      } }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["id"]).to eq id
    end
  end
end
