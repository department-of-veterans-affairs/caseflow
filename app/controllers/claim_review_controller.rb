class ClaimReviewController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application

  def update
    if request_issues_update.perform!
      render json: {
        requestIssues: claim_review.request_issues.map(&:ui_hash),
        addedIssues: request_issues_update.created_issues.map(&:ui_hash),
        removedIssues: request_issues_update.removed_issues.map(&:ui_hash)
      }
    else
      render json: { error_code: request_issues_update.error_code }, status: :unprocessable_entity
    end
  end

  private

  def source_type
    fail "Must override source_type"
  end

  def request_issues_update
    @request_issues_update ||= RequestIssuesUpdate.new(
      user: current_user,
      review: claim_review,
      request_issues_data: params[:request_issues]
    )
  end

  def claim_review
    @claim_review ||= source_type.constantize.find_by_uuid_or_reference_id!(url_claim_id)
  end

  def url_claim_id
    params.permit(:claim_id)[:claim_id]
  end

  helper_method :url_claim_id

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
