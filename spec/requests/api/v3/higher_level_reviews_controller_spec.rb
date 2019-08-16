# frozen_string_literal: true

require "support/database_cleaner"

describe Api::V3::DecisionReview::HigherLevelReviewsController, :postgres, type: :request do
  before do
    FeatureToggle.enable!(:api_v3)
  end
  after do
    FeatureToggle.disable!(:api_v3)
  end

  let!(:api_key) { ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string }

  describe "#create" do
    it "should return a 202 on success" do
      post "/api/v3/decision_review/higher_level_reviews", headers: { "Authorization" => "Token #{api_key}" }
      expect(response).to have_http_status(202)
    end
    it "should be a jsonapi IntakeStatus response" do
      post "/api/v3/decision_review/higher_level_reviews", headers: { "Authorization" => "Token #{api_key}" }
      json = JSON.parse(response.body)
      expect(json["data"].keys).to include("id", "type", "attributes")
      expect(json["data"]["type"]).to eq "IntakeStatus"
      expect(json["data"]["attributes"]["status"]).to be_a String
    end
    it "should include a Content-Location header" do
      post "/api/v3/decision_review/higher_level_reviews", headers: { "Authorization" => "Token #{api_key}" }
      expect(response.headers.keys).to include("Content-Location")
      expect(response.headers["Content-Location"]).to match "/api/v3/decision_review/higher_level_reviews/intake_status"
    end
  end
end
