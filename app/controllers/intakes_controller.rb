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
      }, status: :unprocessable_entity
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
      render json: { error_codes: intake.review_errors }, status: :unprocessable_entity
    end
  rescue StandardError => error
    Raven.capture_exception(error)
    render json: { error_codes: { other: ["unknown_error"] } }, status: :internal_server_error
  end

  def complete
    intake.complete!(params)
    if !intake.detail.is_a?(Appeal) && intake.detail.try(:processed_in_caseflow?)
      flash[:success] = success_message
      render json: { serverIntake: { redirect_to: intake.detail.business_line.tasks_url } }
    else
      render json: intake.ui_hash(ama_enabled?)
    end
  rescue Caseflow::Error::DuplicateEp => error
    render json: {
      error_code: error.error_code,
      error_data: intake.detail.end_product_base_modifier
    }, status: :bad_request
  end

  def error
    intake.save_error!(code: params[:error_code])
    render json: {}
  end

  private

  helper_method :index_props
  def index_props
    {
      userDisplayName: current_user.display_name,
      serverIntake: intake_ui_hash,
      dropdownUrls: dropdown_urls,
      page: "Intake",
      feedbackUrl: feedback_url,
      buildDate: build_date,
      featureToggles: {
        intakeAma: FeatureToggle.enabled?(:intakeAma, user: current_user),
        legacyOptInEnabled: FeatureToggle.enabled?(:intake_legacy_opt_in, user: current_user),
        useAmaActivationDate: FeatureToggle.enabled?(:use_ama_activation_date, user: current_user)
      }
    }
  rescue StandardError => e
    Raven.capture_exception(e)
    # cancel intake so user doesn't get stuck
    intake_in_progress&.cancel!(reason: "system_error")
    flash[:error] = e.message + ". Intake has been cancelled, please retry."
    raise
  end

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

  def intake_ui_hash
    intake_in_progress ? intake_in_progress.ui_hash(FeatureToggle.enabled?(:intakeAma, user: current_user)) : {}
  end

  # TODO: This could be moved to the model.
  def intake_in_progress
    return @intake_in_progress unless @intake_in_progress.nil?

    @intake_in_progress = Intake.in_progress.find_by(user: current_user) || false
  end

  def new_intake
    @new_intake ||= Intake.build(
      user: current_user,
      veteran: veteran,
      form_type: params[:form_type]
    )
  end

  def intake
    @intake ||= Intake.where(user: current_user).find(params[:id])
  end

  def veteran
    # param could be file number or SSN. Make sure we return file number.
    @veteran ||= Veteran.find_or_create_by_file_number_or_ssn(params[:file_number], sync_name: true)
  end

  def success_message
    detail = intake.detail
    claimant_name = detail.veteran_full_name
    claimant_name = detail.claimants.first.try(:name) if detail.veteran_is_not_claimant
    "#{claimant_name} (Veteran SSN: #{detail.veteran.ssn}) #{detail.class.review_title} has been processed."
  end
end
