# frozen_string_literal: true

require "support/database_cleaner"

describe Api::V3::DecisionReview::IntakeStatusesController, :postgres, type: :request do
  before do
    FeatureToggle.enable!(:api_v3)
  end

  after do
    FeatureToggle.disable!(:api_v3)
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Admin Intake"])
  end

  let!(:api_key) do
    ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string
  end

  let(:veteran_file_number) do
    "64205050"
  end

  let(:new_intake) do
    lambda do |detail = nil|
      Intake.create!(
        user: Generators::User.build,
        veteran_file_number: veteran_file_number,
        detail: detail
      )
    end
  end

  describe "#show" do
    it(
      "should return status NOT_SUBMITTED_HTTP_STATUS, the appropriate JSON " \
      "body, and no headers, if decision_review isn't submitted"
    ) do
      hlr = HigherLevelReview.create!(veteran_file_number: veteran_file_number)
      hlr.reload # sets uuid
      new_intake[hlr]

      get(
        "/api/v3/decision_review/intake_statuses/#{hlr.uuid}",
        headers: { "Authorization" => "Token #{api_key}" }
      )

      expect(response).to have_http_status(
        Api::V3::DecisionReview::IntakeStatus::NOT_SUBMITTED_HTTP_STATUS
      )
      expect(JSON.parse(response.body)).to eq(
        "data" => {
          "type" => hlr.class.name,
          "id" => hlr.uuid,
          "attributes" => { "status" => "not_yet_submitted" }
        }
      )
      expect(response.headers).not_to include("Location")
    end

    it(
      "should return status SUBMITTED_HTTP_STATUS, the appropriate JSON " \
      "body, and a Location header, if decision_review /is/ submitted"
    ) do
      hlr = create(:higher_level_review, :requires_processing)
      hlr.reload # sets uuid
      uuid = hlr.uuid
      new_intake[hlr]

      get(
        "/api/v3/decision_review/intake_statuses/#{uuid}",
        headers: { "Authorization" => "Token #{api_key}" }
      )

      expect(response).to have_http_status(
        Api::V3::DecisionReview::IntakeStatus::SUBMITTED_HTTP_STATUS
      )
      expect(JSON.parse(response.body)).to eq(
        "data" => {
          "type" => hlr.class.name,
          "id" => uuid,
          "attributes" => { "status" => "submitted" }
        }
      )
      expect(response.headers).to include("Location")
      expect(response.headers["Location"]).to eq(
        "http://www.example.com/api/v3/decision_review/" \
        "#{hlr.class.name.underscore.pluralize}/#{uuid}"
      )
    end

    it(
      "should return status 404, the appropriate error JSON body, and " \
      "should not have the Location header, if there's no decision review"
    ) do
      uuid = "-0"

      get(
        "/api/v3/decision_review/intake_statuses/#{uuid}",
        headers: { "Authorization" => "Token #{api_key}" }
      )

      expect(response).to have_http_status(404)
      expect(JSON.parse(response.body)).to eq(
        "errors" => [
          {
            "status" => 404,
            "code" => "decision_review_not_found",
            "title" => "Unable to find a DecisionReview with uuid: #{uuid}"
          }
        ]
      )
      expect(response.headers).not_to include("Location")
    end
  end
end
