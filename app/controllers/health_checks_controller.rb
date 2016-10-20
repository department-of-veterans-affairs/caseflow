class HealthChecksController < ApplicationController
  skip_before_action :authenticate
  skip_before_action :authorize

  def show
    render json: { healthy: true }.merge(Rails.application.config.build_version || {})
  end
end
