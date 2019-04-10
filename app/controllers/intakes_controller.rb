# frozen_string_literal: true

class IntakesController < ApplicationController
  before_action :verify_access, :react_routed, :set_application, :check_intake_out_of_service

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
      }, status: :unprocessable_entity
    end
  rescue StandardError => error
    log_error(error)
    # we name the variable error_code to re-use the client error handling.
    render json: { error_code: error_uuid }, status: :internal_server_error
  end

  def destroy
    intake.cancel!(reason: params[:cancel_reason], other: params[:cancel_other])
    render json: {}
  end

  def review
    if intake.review!(params)
      render json: intake.ui_hash
    else
      render json: { error_codes: intake.review_errors }, status: :unprocessable_entity
    end
  rescue StandardError => error
    log_error(error)
    render json: {
      error_codes: { other: ["unknown_error"] },
      error_uuid: error_uuid
    }, status: :internal_server_error
  end

  def complete
    intake.complete!(params)
    if !intake.detail.is_a?(Appeal) && intake.detail.try(:processed_in_caseflow?)
      flash[:success] = success_message
      render json: { serverIntake: { redirect_to: intake.detail.business_line.tasks_url } }
    else
      render json: intake.ui_hash
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

  def log_error(error)
    Raven.capture_exception(error, extra: { error_uuid: error_uuid })
    Rails.logger.error("Error UUID #{error_uuid} : #{error}")
  end

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

  def set_application
    RequestStore.store[:application] = "intake"
  end

  def verify_access
    verify_authorized_roles("Mail Intake", "Admin Intake")
  end

  def check_intake_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("intake_out_of_service")
  end

  def intake_ui_hash
    intake_in_progress ? intake_in_progress.ui_hash : {}
  end

  # TODO: This could be moved to the model.
  def intake_in_progress
    return @intake_in_progress unless @intake_in_progress.nil?

    @intake_in_progress = Intake.in_progress.find_by(user: current_user) || false
  end

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
    veteran = Veteran.find_by_file_number_or_ssn(params[:file_number], sync_name: true)
    veteran ? veteran.file_number : params[:file_number]
  end

  def success_message
    detail = intake.detail
    claimant_name = detail.veteran_full_name
    claimant_name = detail.claimants.first.try(:name) if detail.veteran_is_not_claimant
    "#{claimant_name} (Veteran SSN: #{detail.veteran.ssn}) #{detail.class.review_title} has been processed."
  end
end
