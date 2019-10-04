# frozen_string_literal: true

require "support/intake_helpers"
require "support/database_cleaner"

describe Api::V3::DecisionReview::IntakeStatusesController, :postgres, type: :request do
  before do
    FeatureToggle.enable!(:api_v3)
  end

  after do
    FeatureToggle.disable!(:api_v3)
  end

  let(:veteran_file_number) { "64205050" }

  def fake_intake(detail = nil)
    Intake.create!(
      user: Generators::User.build,
      veteran_file_number: veteran_file_number,
      detail: detail,
    )
  end

  def fake_higher_level_review
    HigherLevelReview.create!(veteran_file_number: veteran_file_number)
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Admin Intake"])
  end

  let!(:api_key) { ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string }

  describe "#show" do
    it "should return a 202 on success" do
      allow(User).to receive(:api_user) do
        val = "ABC"
        User.create!(station_id: val, css_id: val, full_name: val)
      end

      hlr = fake_higher_level_review

      uuid = "cat"
      allow(hlr).to receive(:uuid) { uuid }

      asyncable_status = "dog"
      allow(hlr).to receive(:asyncable_status) { asyncable_status }

      intake = fake_intake(hlr)

      get "/api/v3/decision_review/intake_statuses/#{hlr.uuid}", headers: { "Authorization" => "Token #{api_key}" }

      expect(response.body).to eq("")
      expect(response).to have_http_status(202)
    end
  end
end
