# frozen_string_literal: true

describe Metrics::V2::LogsController, type: :controller do
  let(:current_user) { create(:user) }
  let(:request_params_javascript) do
    {
      metric: {
        uuid: "PAT123456^CFL200^A",
        event_id: "PAT123456^CFL200^A",
        name: "",
        group: "",
        message: "",
        type: "",
        product: ""
      }
    }
  end

  let(:request_params_min) do
    {
      metric: {
        message: "min"
      }
    }
  end

  context "with good request and metrics_monitoring feature ON" do
    before do
      FeatureToggle.enable!(:metrics_monitoring)
    end

    it "creates the metric and returns 200" do
      expect(Metric).to receive(:create_metric_from_rest)
      post :create, params: request_params_javascript
      expect(response.status).to eq(200)
    end

    it "creates the metric and returns 200 for min params" do
      expect(Metric).to receive(:create_metric_from_rest)
      post :create, params: request_params_min
      expect(response.status).to eq(200)
    end
  end

  context "with good request and metrics_monitoring feature OFF" do
    it "does not create a metric and returns 202" do
      expect(Metric).not_to receive(:create_metric_from_rest)
      post :create, params: request_params_javascript
      expect(response.status).to eq(202)
    end
  end
end
