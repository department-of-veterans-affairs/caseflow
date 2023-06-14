# frozen_string_literal: true

class Idt::Api::V1::BaseController < ActionController::Base
  include AuthenticatedControllerAction

  protect_from_forgery with: :exception
  before_action :validate_token
  before_action :set_application
  before_action :set_raven_user

  # :nocov:
  rescue_from StandardError do |error|
    log_error(error)
    uuid = SecureRandom.uuid
    Rails.logger.error("IDT Standard Error ID: " + uuid)
    if error.class.method_defined?(:serialize_response)
      render(error.serialize_response)
    else
      render json: { message: "IDT Standard Error ID: " + uuid + " Unexpected error: #{error.message}" }, status: :internal_server_error
    end
  end
  # :nocov:

  rescue_from ActiveRecord::RecordNotFound do |error|
    log_error(error)
    uuid = SecureRandom.uuid
    Rails.logger.error("IDT Standard Error ID: " + uuid)
    render(json: { message: "IDT Standard Error ID: " + uuid + " Record not found" }, status: :not_found)
  end

  rescue_from Caseflow::Error::InvalidFileNumber do |error|
    log_error(error)
    uuid = SecureRandom.uuid
    Rails.logger.error("IDT Standard Error ID: " + uuid)
    render(json:
            { message:
              "IDT Standard Error ID: " +
                uuid +
                " Please enter a file number in the 'FILENUMBER' header" },
           status: :unprocessable_entity)
  end

  rescue_from Caseflow::Error::MissingRecipientInfo do |error|
    log_error(error)
    uuid = SecureRandom.uuid
    render(json: { message: "Recipient information received was invalid or incomplete.",
                   errors: JSON.parse(error.message) }, status: :bad_request)
  end

  rescue_from Caseflow::Error::VeteranNotFound do |error|
    log_error(error)
    render(json: { message: "IDT Exception ID: " + error.message }, status: :bad_request)
  end

  rescue_from Caseflow::Error::AppealNotFound do |error|
    log_error(error)
    render(json: { message: "IDT Exception ID: " + error.message }, status: :bad_request)
  end

  def validate_token
    return render json: { message: "Missing token" }, status: :bad_request unless token
    return render json: { message: "Invalid token" }, status: :forbidden unless Idt::Token.active?(token)
  end

  def verify_access
    has_access = user.attorney_in_vacols? ||
                 user.judge_in_vacols? ||
                 user.dispatch_user_in_vacols? ||
                 user.intake_user?
    unless has_access
      render json: { message: "User must be attorney, judge, dispatch, or intake" }, status: :forbidden
    end
  end

  def user
    @user ||= begin
      user = User.find_by_css_id(css_id)
      RequestStore.store[:current_user] = user
      user
    end
  end

  # set_raven_user via AuthenticatedControllerAction expects a current_user
  alias current_user user

  def set_application
    RequestStore.store[:application] = "idt"
  end

  def file_number
    request.headers["FILENUMBER"]
  end

  def token
    request.headers["TOKEN"]
  end

  def css_id
    Idt::Token.associated_css_id(token)
  end

  def feature_enabled?(feature)
    FeatureToggle.enabled?(feature, user: user)
  end

  private

  def log_error(error)
    Raven.capture_exception(error)
    Rails.logger.error(error)
    Rails.logger.error(error&.backtrace&.join("\n"))
  end
end
