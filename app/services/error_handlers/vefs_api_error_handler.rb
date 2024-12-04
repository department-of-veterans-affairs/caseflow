# frozen_string_literal: true

class ErrorHandlers::VefsApiErrorHandler
  def handle_error(error:, error_details:)
    report_error_to_sentry(error: error, error_details: error_details)
  end

  private

  def report_error_to_sentry(error:, error_details:)
    Raven.capture_exception(
      error,
      tags: { feature: "vefs_integration" },
      extra: {
        feature_toggle_enabled_vefs_integration: vefs_integration?
      }
    )
  end

  def vefs_integration?
    FeatureToggle.enabled?(:vefs_integration)
  end
end
