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

  let(:new_higher_level_review) do
    HigherLevelReview.create!(veteran_file_number: veteran_file_number)
  end

  # mocked intake and decision review (no DB)
  let(:fake_intake) do
    fake_decision_review = Class.new do
      attr_reader :uuid, :asyncable_status, :class, :intake

      def initialize(opts)
        @uuid, @asyncable_status, @class, @intake = opts.values_at(
          :uuid, :asyncable_status, :class, :intake
        )
      end
    end

    Class.new do
      attr_reader :detail

      # using define_method so that fake_decision_review is in scope
      define_method(:initialize) do |opts = {}|
        @detail = fake_decision_review.new(opts.merge(intake: self))
      end
    end
  end

  describe "ensure the fakes still faithfully mock the real classes" do
    describe "FakeIntake" do
      it "has a :detail method (has a DecisionReview)" do
        expect(fake_intake.new).to respond_to(:detail)
      end

      it "has a detail (DecisionReview) with a :uuid method" do
        expect(fake_intake.new.detail).to respond_to(:uuid)
      end

      it "has a detail with an :asyncable_status method" do
        expect(fake_intake.new.detail).to respond_to(:asyncable_status)
      end

      it "has a detail with an :intake method" do
        expect(fake_intake.new.detail).to respond_to(:intake)
      end
    end

    describe Intake do
      it "has a :detail method" do
        expect(Intake.new).to respond_to(:detail)
      end
    end

    describe HigherLevelReview do
      it "has a :uuid method" do
        expect(HigherLevelReview.new).to respond_to(:uuid)
      end

      it "has an :asyncable_status method" do
        expect(HigherLevelReview.new).to respond_to(:asyncable_status)
      end

      it "has an :intake method" do
        expect(HigherLevelReview.new).to respond_to(:intake)
      end
    end

    describe SupplementalClaim do
      it "has a :uuid method" do
        expect(SupplementalClaim.new).to respond_to(:uuid)
      end

      it "has an :asyncable_status method" do
        expect(SupplementalClaim.new).to respond_to(:asyncable_status)
      end

      it "has an :intake method" do
        expect(SupplementalClaim.new).to respond_to(:intake)
      end
    end

    describe Appeal do
      it "has a :uuid method" do
        expect(Appeal.new).to respond_to(:uuid)
      end

      it "has an :asyncable_status method" do
        expect(Appeal.new).to respond_to(:asyncable_status)
      end

      it "has an :intake method" do
        expect(Appeal.new).to respond_to(:intake)
      end
    end
  end

  describe "#show" do
    it(
      "should return status NOT_SUBMITTED_HTTP_STATUS, the appropriate JSON " \
      "body, and no headers, if decision_review isn't submitted"
    ) do
      hlr = new_higher_level_review
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

      decision_review_class = HigherLevelReview
      uuid = "mouse"
      asyncable_status = :submitted

      intake = fake_intake.new(
        class: decision_review_class,
        uuid: uuid,
        asyncable_status: asyncable_status
      )

      allow(DecisionReview).to receive(:by_uuid) do
        intake.detail
      end

      get(
        "/api/v3/decision_review/intake_statuses/#{uuid}",
        headers: { "Authorization" => "Token #{api_key}" }
      )

      expect(response).to have_http_status(
        Api::V3::DecisionReview::IntakeStatus::SUBMITTED_HTTP_STATUS
      )
      expect(JSON.parse(response.body)).to eq(
        "data" => {
          "type" => decision_review_class.name,
          "id" => uuid,
          "attributes" => { "status" => asyncable_status.to_s }
        }
      )
      expect(response.headers).to include("Location")
      expect(response.headers["Location"]).to eq(
        "http://www.example.com/api/v3/decision_review/" \
        "#{decision_review_class.name.underscore.pluralize}/#{uuid}"
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
