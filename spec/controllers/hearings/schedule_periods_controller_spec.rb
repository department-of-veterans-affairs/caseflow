RSpec.describe Hearings::SchedulePeriodsController, type: :controller do
  context "index" do
    it "returns all schedule periods" do
      get :index, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["schedule_periods"].size).to eq 1
    end
  end
end
