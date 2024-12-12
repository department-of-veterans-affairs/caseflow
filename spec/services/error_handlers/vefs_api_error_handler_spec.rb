# frozen_string_literal: true

describe ErrorHandlers::VefsApiErrorHandler do
  subject(:described) { described_class.new }

  describe "#handle_error" do
    let(:mock_sentry_client) { class_double(Raven) }

    before do
      FeatureToggle.enable!(:vefs_integration)
    end

    after do
      FeatureToggle.disable!(:vefs_integration)
    end

    it "sends the error to its registered clients" do
      error = StandardError.new("Example VEFS API failure")

      expect(Raven).to receive(:capture_exception)
        .with(
          error,
          tags: { feature: "vefs_integration" },
          extra: {
            feature_toggle_enabled_vefs_integration: true
          }
        )

      described.handle_error(error: error, error_details: {})
    end
  end
end
