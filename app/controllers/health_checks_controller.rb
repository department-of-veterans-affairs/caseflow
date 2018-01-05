class HealthChecksController < ActionController::Base
  include TrackRequestId

  protect_from_forgery with: :exception
  newrelic_ignore_apdex

  def show
    body = {
      healthy: true
    }.merge(Rails.application.config.build_version || {})

    render json: body, status: :ok
  end
end
