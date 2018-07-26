class SupplementalClaimsController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application
  SOURCE_TYPE = "SupplementalClaim".freeze

  private

  def supplemental_claim
    @supplemental_claim ||=
      EndProductEstablishment.find_by!(reference_id: params[:claim_id], source_type: SOURCE_TYPE).source
  end

  helper_method :supplemental_claim

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
