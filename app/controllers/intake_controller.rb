class IntakeController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application

  def set_application
    RequestStore.store[:application] = "intake"
  end

  def verify_access
    verify_authorized_roles("Mail Intake")
  end

  def verify_feature_enabled
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:intake)
  end

  def index
    respond_to do |format|
      format.html { render(:index) }
    end
  end

  def create
    if intake.start!
      render json: { success: true }
    else
      render json: { error_code: intake.error_code }, status: 422
    end
  end

  private

  def intake
    @intake ||= RampIntake.new(veteran_file_number: params[:file_number])
  end
end
