require "rails_helper"

RSpec.describe JobsController, type: :controller do
  let!(:current_user) { User.authenticate! }

  before(:each) do
    request.headers["Authorization"] = "Token #{Rails.application.secrets.jobs_auth_token}"
  end

  describe "POST job async_start" do
    it "should not be successful due to unauthorized request" do
      # set up the wrong token
      request.headers["Authorization"] = "BADTOKEN"
      post :start_async, "job_type": "UndefinedJob"
      expect(response.status).to eq 401
    end

    it "should not be successful due to unrecognized job" do
      post :start_async, "job_type": "UndefinedJob"
      expect(response.status).to eq 422
    end

    it "should successfully start HeartbeatTasksJob asynchronously" do
      post :start_async, "job_type": "heartbeat"
      expect(response.status).to eq 200
      expect(response_body["job_id"]).not_to be_empty
    end

    # needed to reach 90% test coverage
    it "should successfully run a job" do
      expect(HeartbeatTasksJob.perform_now).to eq true
    end
  end

  def response_body
    JSON.parse(response.body)
  end
end
