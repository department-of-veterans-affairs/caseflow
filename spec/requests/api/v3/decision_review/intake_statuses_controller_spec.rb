# frozen_string_literal: true

describe Api::V3::DecisionReview::IntakeStatusesController, :postgres, type: :request do
  let!(:current_user) { User.authenticate!(roles: ["Admin Intake"]) }

  let!(:api_key) do
    ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string
  end

  let(:veteran_file_number) do
    "64205050"
  end

  let(:higher_level_review) do
    hlr = create(:higher_level_review, veteran_file_number: veteran_file_number)
    hlr.reload # set uuid
    hlr
  end

  let(:decision_review) { higher_level_review }

  let(:uuid) { intake.detail.uuid }

  let(:intake) do
    intake = create(
      :intake,
      user: Generators::User.build,
      veteran_file_number: veteran_file_number,
      detail: decision_review
    )
    intake.detail = decision_review
    intake
  end

  before do
    FeatureToggle.enable!(:api_v3)

    get(
      "/api/v3/decision_review/intake_statuses/#{uuid}",
      headers: { "Authorization" => "Token #{api_key}" }
    )
  end

  after { FeatureToggle.disable!(:api_v3) }

  describe "#show" do
    context "unprocessed decision review" do
      let(:higher_level_review) do
        hlr = create(:higher_level_review, :requires_processing)
        hlr.reload # set uuid
        hlr
      end

      it "returns status NOT_PROCESSED_HTTP_STATUS" do
        expect(response).to have_http_status(
          Api::V3::DecisionReview::IntakeStatus::NOT_PROCESSED_HTTP_STATUS
        )
      end

      it "is correctly shaped" do
        expect(JSON.parse(response.body).keys).to contain_exactly("data")
        expect(JSON.parse(response.body)["data"]).to be_a Hash
        expect(JSON.parse(response.body)["data"].keys).to contain_exactly("id", "type", "attributes")
        expect(JSON.parse(response.body)["data"]["attributes"]).to be_a Hash
        expect(JSON.parse(response.body)["data"]["attributes"].keys).to contain_exactly("status")
      end

      it "has the correct values" do
        expect(JSON.parse(response.body)["data"]["type"]).to eq(decision_review.class.name)
        expect(JSON.parse(response.body)["data"]["id"]).to eq(uuid)
        expect(JSON.parse(response.body)["data"]["attributes"]["status"]).to eq("submitted")
      end

      it "does not have the Location header" do
        expect(response.headers).not_to include("Location")
      end
    end

    context "processed decision review" do
      let(:higher_level_review) do
        hlr = create(:higher_level_review, :processed)
        hlr.reload # set uuid
        hlr
      end

      it "returns status PROCESSED_HTTP_STATUS" do
        expect(response).to have_http_status(
          Api::V3::DecisionReview::IntakeStatus::PROCESSED_HTTP_STATUS
        )
      end

      it "is correctly shaped" do
        expect(JSON.parse(response.body).keys).to contain_exactly("meta")
        expect(JSON.parse(response.body)["meta"]).to be_a Hash
        expect(JSON.parse(response.body)["meta"].keys).to contain_exactly("Location")
        expect(JSON.parse(response.body)["meta"]["Location"]).to be_a String
      end

      it "returns the correct UUID" do
        expect(JSON.parse(response.body)["meta"]["Location"].split("/").last).to eq(decision_review.uuid)
      end

      it "has the Location header" do
        expect(response.headers).to include("Location")
      end

      it "returns the location of the decision_review" do
        expect(response.headers["Location"]).to eq(
          "http://www.example.com/api/v3/decision_review/" \
          "#{decision_review.class.name.underscore.pluralize}/#{uuid}"
        )
      end
    end

    context "bad uuid" do
      let(:uuid) { "-0" }

      it "is correctly shaped" do
        expect(JSON.parse(response.body).keys).to contain_exactly("errors")
        expect(JSON.parse(response.body)["errors"]).to be_a(Array)
        expect(JSON.parse(response.body)["errors"].length).to eq(1)
        expect(JSON.parse(response.body)["errors"][0]).to be_a(Hash)
        expect(JSON.parse(response.body)["errors"][0].keys).to contain_exactly("status", "code", "title")
      end

      it "returns http status 404" do
        expect(response).to have_http_status(404)
        expect(JSON.parse(response.body)["errors"][0]["status"]).to be 404
      end

      it "does not have the Location header" do
        expect(response.headers).not_to include("Location")
      end
    end
  end
end
