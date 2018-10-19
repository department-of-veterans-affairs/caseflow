class SupplementalClaimsController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application
  SOURCE_TYPE = "SupplementalClaim".freeze

  def update
    if request_issues_update.perform!
      render json: {
        requestIssues: supplemental_claim.request_issues.map(&:ui_hash)
      }
    else
      render json: { error_code: request_issues_update.error_code }, status: 422
    end
  end

  private

  def request_issues_update
    @request_issues_update ||= RequestIssuesUpdate.new(
      user: current_user,
      review: supplemental_claim,
      request_issues_data: params[:request_issues]
    )
  end

  def end_product_establishment
    @end_product_establishment ||=
      EndProductEstablishment.find_by!(reference_id: params[:claim_id], source_type: SOURCE_TYPE)
  end

  def supplemental_claim
    @supplemental_claim ||=
      end_product_establishment.source
  end

  helper_method :supplemental_claim, :end_product_establishment

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
