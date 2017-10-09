class IntakeController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application

  def set_application
    RequestStore.store[:application] = "intake"
  end

  def verify_access
    verify_authorized_roles("Mail Intake")
  end

  def verify_feature_enabled
    puts 'verify_feature_enabled unauthorized'
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:intake)
  end

  def index
    respond_to do |format|
      format.html { render(:index) }
    end
  end
end
