# frozen_string_literal: true

class Api::V3::BaseController < Api::ApplicationController
  protect_from_forgery with: :null_session
  before_action :api_released?

  def api_released?
    return true if FeatureToggle.enabled?(:api_v3)

    render json: {
      errors: [
        {
          status: "501",
          title: "Not Implemented",
          detail: "This endpoint is not yet supported."
        }
      ]
    },
           status: :not_implemented
  end

  def render_errors(errors)
    errors = Array.wrap(errors)
    status = status_from_errors errors
    render status: status, json: { errors: errors }
  end

  def status_from_errors(errors)
    errors.map { |error| error[:status] || error["status"] }.max
  rescue StandardError
    500
  end
end
