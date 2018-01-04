class HealthChecksController < ActionController::Base
  include TrackRequestId

  protect_from_forgery with: :exception
  newrelic_ignore_apdex

  def show
    render json: Rails.application.config.build_version || {}, status: :ok
  end
end
