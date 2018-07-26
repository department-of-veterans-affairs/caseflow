class HigherLevelReviewsController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application
  SOURCE_TYPE = "HigherLevelReview".freeze

  private

  def higher_level_review
    @higher_level_review ||=
      EndProductEstablishment.find_by!(reference_id: params[:claim_id], source_type: SOURCE_TYPE).source
  end

  helper_method :higher_level_review

  def set_application
    RequestStore.store[:application] = "intake"
  end

  def verify_access
    verify_authorized_roles("Mail Intake", "Admin Intake")
  end

  def verify_feature_enabled
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:intake)
  end
end
