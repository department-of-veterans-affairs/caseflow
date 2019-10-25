# frozen_string_literal: true

require "support/database_cleaner"

describe Api::V3::DecisionReview::IssuesController, :postgres, type: :request do
  before { FeatureToggle.enable!(:api_v3) }
  after { FeatureToggle.disable!(:api_v3) }

  describe "#index" do
    let(:veteran_file_number) { "64205050" }
    let!(:api_key) do
      ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string
    end
    def get_issues(veteran_id:veteran_file_number,receipt_date:Date.today)
      get(
        "/api/v3/decision_review/issues?",
        headers: {
          "Authorization" => "Token #{api_key}",
          "veteranId" => veteran_file_number,
          "receiptDate" => receipt_date.strftime("%Y-%m-%d")
        }
      )
    end

    it 'should return a 200 OK' do
      get_issues
      expect(response).to have_http_status(:ok)
    end
    it 'should return a list of issues'
    it 'should return a 404 when the veteran is not found'
    it 'should return a 422 when the receipt date is bad'
  end
end
