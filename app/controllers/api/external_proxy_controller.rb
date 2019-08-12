# frozen_string_literal: true

class Api::ExternalProxyController < ActionController::Base
  protect_from_forgery with: :null_session

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
end
