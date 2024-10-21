# frozen_string_literal: true

# Uses the BGSService to check a user's sensitivity level,
# which is used to control access to a veteran's information
class SensitivityChecker
  def initialize(current_user)
    self.current_user = current_user
  end

  def sensitivity_levels_compatible?(user:, veteran:)
    bgs_service.sensitivity_level_for_user(user) >=
      bgs_service.sensitivity_level_for_veteran(veteran)
  rescue StandardError => error
    report_error(error)

    false
  end

  def sensitivity_level_for_user(user)
    bgs_service.sensitivity_level_for_user(user)
  rescue StandardError => error
    report_error(error)

    nil
  end

  private

  attr_accessor :current_user

  def bgs_service
    return @bgs_service if @bgs_service.present?

    # Set for use by BGSService
    RequestStore.store[:current_user] ||= current_user

    @bgs_service = BGSService.new
  end

  def error_handler
    @error_handler ||= ErrorHandlers::ClaimEvidenceApiErrorHandler.new
  end

  def report_error(error)
    error_details = {
      user_css_id: RequestStore[:current_user]&.css_id || "User is not set in RequestStore",
      user_sensitivity_level: "Error occurred in SensitivityChecker",
      error_uuid: SecureRandom.uuid
    }
    error_handler.handle_error(error: error, error_details: error_details)
  end
end
