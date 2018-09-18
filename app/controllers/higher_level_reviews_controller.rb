class HigherLevelReviewsController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application
  SOURCE_TYPE = "HigherLevelReview".freeze

  def update
    if request_issues_update.perform!
      render json: {
        ratings: higher_level_review.cached_serialized_timely_ratings,
        ratedRequestIssues: higher_level_review.request_issues.rated.map(&:ui_hash)
      }
    else
      render json: { error_code: request_issues_update.error_code }, status: 422
    end
  end

  private

  def request_issues_update
    @request_issues_update ||= RequestIssuesUpdate.new(
      user: current_user,
      review: higher_level_review,
      request_issues_data: params[:request_issues]
    )
  end

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
