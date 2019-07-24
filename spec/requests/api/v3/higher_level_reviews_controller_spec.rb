# frozen_string_literal: true

describe Api::V3::DecisionReview::HigherLevelReviewsController, type: :request do
=begin
  describe "#mock_create" do
    it "should return a 202 on success" do
      post "/api/v3/decision_review/higher_level_reviews"
      expect(response).to have_http_status(202)
    end
    it "should be a jsonapi IntakeStatus response" do
      post "/api/v3/decision_review/higher_level_reviews"
      json = JSON.parse(response.body)
      expect(json["data"].keys).to include("id", "type", "attributes")
      expect(json["data"]["type"]).to eq "IntakeStatus"
      expect(json["data"]["attributes"]["status"]).to be_a String
    end
    it "should include a Content-Location header" do
      post "/api/v3/decision_review/higher_level_reviews"
      expect(response.headers.keys).to include("Content-Location")
      expect(response.headers["Content-Location"]).to match "/api/v3/decision_review/higher_level_reviews/intake_status"
    end
  end
=end
  describe "#create" do
    it "should return a 202 on success" do
      post("/api/v3/decision_review/higher_level_reviews",
           params: {
             "data" => {
               "type" => "HigherLevelReview",
               "attributes" => {
                 "receiptDate" => "2019-07-10",
                 "informalConference" => true,
                 "sameOffice" => false,
                 "legacyOptInApproved" => true,
                 "benefitType" => "pension"
               },
               "relationships" => {
                 "veteran" => {
                   "data" => {
                     "type" => "Veteran",
                     "id" => "55555555"
                   }
                 },
                 "claimant" => {
                   "data" => {
                     "type" => "Claimant",
                     "id" => "44444444",
                     "meta" => {
                       "payeeCode" => "10"
                     }
                   }
                 }
               }
             },
             "included" => [
               {
                 "type" => "nonrating_issue",
                 "attributes" => {
                   "decisionText" => "veteran status verified",
                   "decisionDate" => "2019-07-11",
                   "nonratingIssueCategory" => "Eligibility | Veteran Status"
                 }
               },
               {
                 "type" => "rating_issue",
                 "id" => "def456"
               }
             ]
           })
      expect(response).to have_http_status(202)
    end
  end
end
