class DecisionReviewsController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application

  def index
    if business_line
      render json: { tasks: business_line.tasks }
    else
      render json: { error: "#{business_line_slug} not found" }, status: 404
    end
  end

  private

  def business_line_slug
    params.permit(:business_line_slug)[:business_line_slug]
  end

  def business_line
    @business_line ||= NonComp.find_by(url: business_line_slug)
  end

  def set_application
    RequestStore.store[:application] = "decision_reviews"
  end

  # TODO: authz rules for this space
  def verify_access
    return false unless business_line
    return true if current_user.admin?
    return true if business_line.user_has_access?(current_user)

    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  def verify_feature_enabled
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:decision_reviews)
  end
end
