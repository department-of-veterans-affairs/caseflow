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
    if new_intake.start!
      render json: new_intake.ui_hash
    else
      render json: {
        error_code: new_intake.error_code,
        error_data: new_intake.error_data
      }, status: 422
    end
  end

  def destroy
    current_intake.cancel!
    render json: {}
  end

  def review
    if current_intake.review!(params)
      render json: {}
    else
      render json: { error_codes: current_intake.review_errors }, status: 422
    end
  end

  def complete
    current_intake.complete!(params)
    render json: current_intake.ui_hash
  end

  def error
    # custom error code ineligible_for_higher_level_review: "ineligible_for_higher_level_review" for
    #  RampRefilingIntake
    # error completion_status for RampRefilingIntake in intakes table
    # delete associated ramp_refiling record for RampRefilingIntake
  end

  private

  def no_cache
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def fetch_current_intake
    @current_intake = Intake.in_progress.find_by(user: current_user)
  end

  def new_intake
    @new_intake ||= Intake.build(
      user: current_user,
      veteran_file_number: params[:file_number],
      form_type: form_type
    )
  end

  def current_intake
    @intake ||= Intake.where(user: current_user).find(params[:id])
  end

  def form_type
    FeatureToggle.enabled?(:intake_reentry_form) ? params[:form_type] : "ramp_election"
  end
end
