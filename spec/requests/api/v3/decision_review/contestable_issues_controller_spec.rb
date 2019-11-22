# frozen_string_literal: true

require "support/database_cleaner"

describe Api::V3::DecisionReview::ContestableIssuesController, :postgres, type: :request do
  before { FeatureToggle.enable!(:api_v3) }
  after { FeatureToggle.disable!(:api_v3) }

  describe "#index" do
    let(:veteran) { create(:veteran) }

    let!(:api_key) do
      ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string
    end

    def get_issues(veteran_id: veteran.file_number, receipt_date: Time.zone.today)
      get(
        "/api/v3/decision_review/contestable_issues",
        headers: {
          "Authorization" => "Token #{api_key}",
          "veteranId" => veteran_id,
          "receiptDate" => receipt_date.strftime("%Y-%m-%d")
        }
      )
    end

    it "should return a 200 OK" do
      get_issues
      expect(response).to have_http_status(:ok)
    end

    fit "should return a list of issues" do
      Generators::Rating.build(
        participant_id: veteran.ptcpnt_id,
        profile_date: Time.zone.today - 10.days # must be before receipt_date
      ) # this is a contestable_rating_issues
      get_issues
      issues = JSON.parse(response.body)
      expect(issues).to be_an Array
      expect(issues.count > 0).to be true
    end

    context "returned issues" do
      it "should have meaningful attributes"
    end

    it "should return a 404 when the veteran is not found" do
      get_issues(veteran_id: "abcdefg")
      expect(response).to have_http_status(:not_found)
    end

    it "should return a 422 when the receipt date is bad" do
      get_issues(receipt_date: Time.zone.today - 1000.years)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
