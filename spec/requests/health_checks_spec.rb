# frozen_string_literal: true

describe "Health Check API" do
  context "mock" do
    before do
      Rails.application.config.build_version = { deployed_at: "the best day ever" }
    end

    it "should fail health check when pushgateway is offline" do
      allow_any_instance_of(Caseflow::PushgatewayService).to receive(:healthy?) { false }

      get "/health-check"

      expect(response).to have_http_status(503)

      json = JSON.parse(response.body)
      expect(json["healthy"]).to eq(false)
      expect(json["deployed_at"]).to eq("the best day ever")
    end

    it "should pass health check when pushgateway is online" do
      allow_any_instance_of(Caseflow::PushgatewayService).to receive(:healthy?) { true }

      get "/health-check"

      expect(response).to be_success

      json = JSON.parse(response.body)
      expect(json["healthy"]).to eq(true)
      expect(json["deployed_at"]).to eq("the best day ever")
    end
  end
end
