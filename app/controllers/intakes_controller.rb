class IntakesController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application, :check_intake_out_of_service

  def index
    no_cache

    respond_to do |format|
      format.html { render(:index) }
    end
  end

  def create
    return render json: intake_in_progress.ui_hash(ama_enabled?) if intake_in_progress

    if new_intake.start!
      render json: new_intake.ui_hash(ama_enabled?)
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
      render json: intake.ui_hash(ama_enabled?)
    else
      render json: { error_codes: intake.review_errors }, status: 422
    end
  rescue StandardError => error
    Raven.capture_exception(error)
    render json: { error_codes: { other: ["unknown_error"] } }, status: 500
  end

  def complete
    intake.complete!(params)
    render json: intake.ui_hash(ama_enabled?)
  rescue Caseflow::Error::DuplicateEp => error
    render json: {
      error_code: error.error_code,
      error_data: intake.detail.end_product_base_modifier
    }, status: 400
  end

  def error
    intake.save_error!(code: params[:error_code])
    render json: {}
  end

  private

  def ama_enabled?
    FeatureToggle.enabled?(:intakeAma, user: current_user)
  end

  def set_application
    RequestStore.store[:application] = "intake"
  end

  def verify_access
    verify_authorized_roles("Mail Intake", "Admin Intake")
  end

  def verify_feature_enabled
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:intake)
  end

  def check_intake_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("intake_out_of_service")
  end

  # TODO: This could be moved to the model.
  def intake_in_progress
    return @intake_in_progress unless @intake_in_progress.nil?
    @intake_in_progress = Intake.in_progress.find_by(user: current_user) || false
  end
  helper_method :intake_in_progress

  def new_intake
    @new_intake ||= Intake.build(
      user: current_user,
      veteran_file_number: veteran_file_number,
      form_type: params[:form_type]
    )
  end

  def intake
    @intake ||= Intake.where(user: current_user).find(params[:id])
  end

  def veteran_file_number
    # param could be file number or SSN. Make sure we return file number.
    veteran = VeteranFinder.new.find(params[:file_number])
    veteran ? veteran.file_number : params[:file_number]
  end
end
