class IntakesController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application
  before_action :fetch_current_intake

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
    no_cache

    respond_to do |format|
      format.html { render(:index) }
    end
  end

  def create
    if intake.start!
      render json: ramp_intake_data(intake)
    else
      render json: {
        error_code: intake.error_code,
        error_data: intake.error_data
      }, status: 422
    end
  end

  private

  def no_cache
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def ramp_intake_data(ramp_intake)
    ramp_intake ? ramp_intake.ui_hash : {}
  end
  helper_method :ramp_intake_data

  def fetch_current_intake
    @current_intake = RampIntake.in_progress.find_by(user: current_user)
  end

  def intake
    @intake ||= RampIntake.new(user: current_user, veteran_file_number: params[:file_number])
  end
end
