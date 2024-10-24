# frozen_string_literal: true

class ErrorHandlers::ClaimEvidenceApiErrorHandler
  def handle_error(error:, error_details:)
    report_error_to_sentry(error: error, error_details: error_details)
  end

  private

  def report_error_to_sentry(error:, error_details:)
    Raven.capture_exception(
      error,
      tags: { feature: "claim_evidence_api" },
      extra: {
        feature_toggle_enabled_use_ce_api: use_ce_api?,
        feature_toggle_enabled_send_current_user_cred_to_ce_api: send_current_user_cred_to_ce_api?,
        user_css_id: error_details[:user_css_id],
        user_sensitivity_level: error_details[:user_sensitivity_level],
        error_uuid: error_details[:error_uuid]
      }
    )
  end

  def send_current_user_cred_to_ce_api?
    FeatureToggle.enabled?(:send_current_user_cred_to_ce_api)
  end

  def use_ce_api?
    FeatureToggle.enabled?(:use_ce_api)
  end
end
