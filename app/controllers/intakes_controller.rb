# frozen_string_literal: true

class IntakesController < ApplicationController
  include ValidationConcern

  before_action :verify_access, except: %i[attorneys]
  before_action :react_routed, :set_application, :check_intake_out_of_service

  attr_accessor :error_id

  def index
    no_cache

    respond_to do |format|
      format.html { render(:index) }
    end
  end

  validates :create, using: IntakesSchemas.create
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
    render json: { error_code: error_id }, status: :internal_server_error
  end

  def destroy
    intake.cancel!(reason: params[:cancel_reason], other: params[:cancel_other])
    render json: {}
  end

  validates :review, using: IntakesSchemas.review
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
      error_uuid: error_id
    }, status: :internal_server_error
  end

  def complete
    intake.complete!(params)
    if !detail.is_a?(Appeal) && detail.try(:processed_in_caseflow?)
      flash[:success] = success_message
      render json: { serverIntake: { redirect_to: detail.business_line.tasks_url } }
    else
      render json: intake.ui_hash
    end
  rescue Caseflow::Error::DuplicateEp => error
    render json: {
      error_code: error.error_code,
      error_data: detail.end_product_base_modifier
    }, status: :bad_request
  rescue StandardError => error
    log_error(error)
    render json: { error_code: "default", error_uuid: error_id }, status: :internal_server_error
  end

  def attorneys
    results = AttorneySearch.new(params[:query]).fetch_attorneys.map do |attorney|
      attorney.as_json.extract!("name", "participant_id").merge("address": attorney.address.as_json)
    end
    render json: results
  end

  def error
    intake.save_error!(code: params[:error_code])
    render json: {}
  end

  private

  def log_error(error)
    Raven.capture_exception(error)
    self.error_id = Raven.last_event_id || "00000000000000000123456789abcdef"
    Rails.logger.error("Intake error (Sentry event #{error_id}): #{error}\n" + error.backtrace.join("\n"))
  end

  helper_method :index_props
  def index_props
    {
      userDisplayName: current_user.display_name,
      userCanIntakeAppeals: current_user.can_intake_appeals?,
      serverIntake: intake_ui_hash,
      dropdownUrls: dropdown_urls,
      page: "Intake",
      feedbackUrl: feedback_url,
      buildDate: build_date,
      featureToggles: {
        useAmaActivationDate: FeatureToggle.enabled?(:use_ama_activation_date, user: current_user),
        rampIntake: FeatureToggle.enabled?(:ramp_intake, user: current_user),
        covidTimelinessExemption: FeatureToggle.enabled?(:covid_timeliness_exemption, user: current_user)
      }
    }
  rescue StandardError => error
    Rails.logger.error "#{error.message}\n#{error.backtrace.join("\n")}"
    Raven.capture_exception(error)
    # cancel intake so user doesn't get stuck
    intake_in_progress&.cancel!(reason: "system_error")
    flash[:error] = error.message + ". Intake has been cancelled, please retry."
    raise
  end

  def set_application
    RequestStore.store[:application] = "intake"
  end

  def verify_access
    if !current_user.can_intake_decision_reviews?
      redirect_to "/unauthorized"
    else
      verify_authorized_roles("Mail Intake", "Admin Intake")
    end
  end

  def check_intake_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("intake_out_of_service")
  end

  def unread_messages?
    current_user.messages.unread.count > 0
  end

  def intake_ui_hash
    return intake_in_progress.ui_hash.merge(unread_messages: unread_messages?) if intake_in_progress

    { unread_messages: unread_messages? }
  end

  # TODO: This could be moved to the model.
  def intake_in_progress
    return @intake_in_progress unless @intake_in_progress.nil?

    @intake_in_progress = Intake.in_progress.find_by(user: current_user)
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

  def detail
    @detail ||= intake&.detail
  end

  def veteran_file_number
    # param could be file number or SSN. Make sure we return file number.
    veteran = Veteran.find_by_file_number_or_ssn(params[:file_number], sync_name: true)
    veteran ? veteran.file_number : params[:file_number]
  end

  def success_message
    claimant_name = detail.veteran_full_name
    claimant_name = detail.claimant.try(:name) if detail.veteran_is_not_claimant
    "#{claimant_name} (Veteran SSN: #{detail.veteran.ssn}) #{detail.class.review_title} has been processed."
  end
end
