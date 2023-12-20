# frozen_string_literal: true

describe "Health Check API" do
  context "mock" do
    before do
      Rails.application.config.build_version = { deployed_at: "the best day ever" }
    end

    it "should pass health check" do
      get "/health-check"

      expect(response).to be_successful

      json = JSON.parse(response.body)
      expect(json["healthy"]).to eq(true)
      expect(json["deployed_at"]).to eq("the best day ever")
    end
  end
end
