# frozen_string_literal: true

module ApiFeatureToggleConcern
  extend ActiveSupport::Concern

  def api_released?(feature)
    return true if FeatureToggle.enabled?(feature)

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
