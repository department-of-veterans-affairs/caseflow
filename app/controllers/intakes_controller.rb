class IntakesController < ApplicationController
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

  def index
    no_cache

    respond_to do |format|
      format.html { render(:index) }
    end
  end

  def create
    return render json: intake_in_progress.ui_hash if intake_in_progress

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
    intake.cancel!(reason: params[:cancel_reason], other: params[:cancel_other])
    render json: {}
  end

  def review
    if intake.review!(params)
      render json: {}
    else
      render json: { error_codes: intake.review_errors }, status: 422
    end
  end

  def complete
    intake.complete!(params)
    render json: intake.ui_hash
  rescue Caseflow::Error::DuplicateEp => error
    render json: {
      error_code: error.error_code,
      error_data: intake.detail.pending_end_product_description
    }, status: 400
  end

  def error
    intake.save_error!(code: params[:error_code])
    render json: {}
  end

  private

  def no_cache
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def intake_in_progress
    return @intake_in_progress unless @intake_in_progress.nil?
    @intake_in_progress = Intake.in_progress.find_by(user: current_user) || false
  end
  helper_method :intake_in_progress

  def new_intake
    @new_intake ||= Intake.build(
      user: current_user,
      veteran_file_number: params[:file_number],
      form_type: params[:form_type]
    )
  end

  def intake
    @intake ||= Intake.where(user: current_user).find(params[:id])
  end
end
