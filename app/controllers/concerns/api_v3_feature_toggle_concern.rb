# frozen_string_literal: true

module ApiV3FeatureToggleConcern
  extend ActiveSupport::Concern

  def api_released?(feature)
    return true if FeatureToggle.enabled?(feature)

    # return true if feature == :ama_eventing_enabled

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
