# frozen_string_literal: true

module AuthenticatedControllerAction
  extend ActiveSupport::Concern

  def set_raven_user
    return unless sentry_reporting_is_live?

    if current_user
      # Raven sends error info to Sentry.
      Raven.user_context(
        email: current_user.email,
        css_id: current_user.css_id,
        station_id: current_user.station_id,
        regional_office: current_user.regional_office
      )
    end
  end

  def sentry_reporting_is_live?
    ENV["SENTRY_DSN"]
  end
end
