# frozen_string_literal: true

RSpec.describe Api::V1::JobsController, :postgres, type: :controller do
  let!(:current_user) { User.authenticate! }
  let(:api_key) { ApiKey.create!(consumer_name: "Jobs Tester") }

  before(:each) do
    request.headers["Authorization"] = "Token #{api_key.key_string}"
  end

  describe "POST job create" do
    it "should not be successful due to unauthorized request" do
      # set up the wrong token
      request.headers["Authorization"] = "BADTOKEN"
      post :create, params: { "job_type": "UndefinedJob" }
      expect(response.status).to eq 401
    end

    it "should not be successful due to unrecognized job" do
      post :create, params: { "job_type": "UndefinedJob" }
      expect(response.status).to eq 422
    end

    it "should successfully start StatsCollectorJob asynchronously" do
      allow(StatsCollectorJob).to receive(:perform_later).and_return(StatsCollectorJob.new)
      post :create, params: { "job_type": "stats_collector" }
      expect(response.status).to eq 200
      expect(response_body["job_id"]).not_to be_empty
    end

    # needed to reach 90% test coverage
    it "should successfully run a job" do
      expect(HeartbeatTasksJob.perform_now).to eq 53
    end
  end

  def response_body
    JSON.parse(response.body)
  end
end
