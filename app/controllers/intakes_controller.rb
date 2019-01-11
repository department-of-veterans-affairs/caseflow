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
    fail VBMS::HTTPError.new(nil, '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"><env:Header/><env:Body><env:Fault><faultcode>env:Server</faultcode><faultstring>Claim creation failed. System error. GUID: 2dd5a89d-f325-4e54-8d67-8f63d6d4baa2</faultstring><detail><ns4:serviceException xmlns:ns4="http://vbms.vba.va.gov/external/ClaimService/v4" xmlns:ns3="http://vbms.vba.va.gov/cdm/participant/v4" xmlns:ns1="http://vbms.vba.va.gov/cdm/common/v4" xmlns:ns0="http://vbms.vba.va.gov/cdm/claim/v4"><ns4:exception>VBMS does not currently support claim establishment of claimants with a fiduciary. Please establish this claim in an appropriate source system.</ns4:exception><ns4:message>Claim creation failed. System error.</ns4:message></ns4:serviceException></detail></env:Fault></env:Body></env:Envelope>')

    render json: intake.ui_hash(ama_enabled?)
  rescue Caseflow::Error::DuplicateEp => error
    render json: {
      error_code: error.error_code,
      error_data: intake.detail.end_product_base_modifier
    }, status: :bad_request
  rescue VBMS::HTTPError => error
    Raven.capture_exception(error)
    message = error.try(:body).to_s
    if message.match?("does not currently support claim establishment of claimants with a fiduciary")
      render json: {
        error_code: :claimant_with_fiduciary,
        error_data: nil
      }, status: :bad_request
    end
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
    veteran = Veteran.find_by_file_number_or_ssn(params[:file_number])
    veteran ? veteran.file_number : params[:file_number]
  end
end
