# frozen_string_literal: true

require "rails_helper"

describe ErrorHandlers::ClaimEvidenceApiErrorHandler do
  subject(:described) { described_class.new }

  describe "#handle_error" do
    let(:mock_sentry_client) { class_double(Raven) }

    before do
      FeatureToggle.enable!(:use_ce_api)
      FeatureToggle.enable!(:send_current_user_cred_to_ce_api)
    end

    after do
      FeatureToggle.disable!(:use_ce_api)
      FeatureToggle.disable!(:send_current_user_cred_to_ce_api)
    end

    it "sends the error to its registered clients" do
      error = StandardError.new("Example CE API failure")

      expect(Raven).to receive(:capture_exception)
        .with(
          error,
          tags: { feature: "claim_evidence_api" },
          extra: {
            feature_toggle_enabled_use_ce_api: true,
            feature_toggle_enabled_send_current_user_cred_to_ce_api: true,
            user_css_id: "USER_12345",
            user_sensitivity_level: 4,
            error_uuid: "1234-1234-1234"
          }
        )

      error_details = {
        user_css_id: "USER_12345",
        user_sensitivity_level: 4,
        error_uuid: "1234-1234-1234"
      }

      described.handle_error(error: error, error_details: error_details)
    end
  end
end
