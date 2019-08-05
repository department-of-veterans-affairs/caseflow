# frozen_string_literal: true

class Api::Docs::V3::DocsController < Api::ExternalProxyController
  before_action :is_api_released? #TODO move this to shared external controller
  def decision_reviews
    swagger = YAML.safe_load(File.read("app/controllers/api/docs/v3/decision_reviews.yaml"))
    render json: swagger
  end

  private

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
