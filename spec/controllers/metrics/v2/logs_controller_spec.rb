# frozen_string_literal: true

describe Metrics::V2::LogsController, type: :controller do

  let(:request_params_javascript) do
    {
      metric: {
        method: "123456789",
        uuid: "PAT123456^CFL200^A",
        url: '',
        message: '',
        isError: false,
        isPerformance: false,
        source: 'javascript'
      }
    }
  end

  let(:request_params_min) do
    {
      metric: {
        message: 'min'
      }
    }
  end


  context "with good request" do
    it "returns 200 for javascript source" do
      expect(Metric).to receive(:create_javascript_metric).and_return(nil)
      post :create, params: request_params_javascript
      expect(response.status).to eq(200)
    end

    it "returns 200 for min params" do
      post :create, params: request_params_min
      expect(response.status).to eq(200)
    end
  end
end
