# frozen_string_literal: true

class Api::ExternalProxyController < ActionController::Base
  protect_from_forgery with: :null_session

  def is_api_released?
    return if FeatureToggle.enabled?(:external_api_released)
    render json: {
        errors: [
          {
            status: "501",
            title:  "Not Implemented",
            detail: "This endpoint is not yet supported."
          }
        ]
      }, status: 501
  end
end
