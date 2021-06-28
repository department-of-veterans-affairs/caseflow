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

    it "should successfully start HeartbeatTasksJob asynchronously" do
      allow(HeartbeatTasksJob).to receive(:perform_later).and_return(HeartbeatTasksJob.new)
      post :create, params: { "job_type": "heartbeat" }
      expect(response.status).to eq 200
      expect(response_body["job_id"]).not_to be_empty
    end

    # needed to reach 90% test coverage
    it "should successfully run a job" do
      expect(HeartbeatTasksJob.perform_now).to eq true
    end
  end

  context "for all jobs" do
    Api::V1::JobsController::SUPPORTED_JOBS.each_value do |job_class|
      it "#{job_class.name} is not queued in default queue" do
        expect(job_class.queue_name).not_to eq("default")
      end
    end
  end

  def response_body
    JSON.parse(response.body)
  end
end
