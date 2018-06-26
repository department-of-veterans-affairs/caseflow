class SupplementalClaimsController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application

  def set_application
    RequestStore.store[:application] = "intake"
  end

  def verify_access
    verify_authorized_roles("Mail Intake", "Admin Intake")
  end

  def verify_feature_enabled
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:intake)
  end

  def edit
    render json: {
      claim_id: params[:claim_id]
    }
  end
end
