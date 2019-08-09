# frozen_string_literal: true

class Api::ExternalProxyController < ActionController::Base
  protect_from_forgery with: :null_session

  def api_released?(api_name = controller_as_api_feature_name)
    return true if FeatureToggle.enabled?(api_name)

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

  # This method smells of :reek:ControlParameter
  def controller_as_api_feature_name(cntrlr = self.class.name)
    case cntrlr
    when "Api::V3::DecisionReview::HigherLevelReviewsController"
      :higher_level_review_api
    end
  end
end
