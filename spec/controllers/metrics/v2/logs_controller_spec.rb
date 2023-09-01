# frozen_string_literal: true

describe Metrics::V2::LogsController, type: :controller do
  let(:current_user) { create(:user) }
  let(:request_params) do
    {
      metric: {
        uuid: SecureRandom.uuid,
        method: "123456789",
        name: 'log',
        group: 'service',
        message: 'This is a test',
        type: 'performance',
        product: 'reader',
       }
    }
  end

  before do
    @raven_called = false
  end
  before { User.authenticate!(user: current_user) }

  context "with good request" do
    it "returns 200 for request params" do
      post :create, params: request_params
      expect(@raven_called).to eq(false)
      expect(response.status).to eq(200)
    end
  end

  context "With error type record to sentry" do
    it "Records to Sentry" do
      capture_raven_log
      request_params[:metric][:type] = 'error'
      post :create, params: request_params
      expect(@raven_called).to eq(true)
    end
  end

  def capture_raven_log
    allow(Raven).to receive(:capture_exception) { @raven_called = true }
  end
end
