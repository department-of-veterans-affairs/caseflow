class HealthChecksController < ApplicationController
  skip_before_action :verify_authentication

  def show
    body = {
      healthy: true
    }.merge(Rails.application.config.build_version || {})

    render json: body
  end
end
