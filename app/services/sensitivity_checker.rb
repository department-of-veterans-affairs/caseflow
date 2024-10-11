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
    error_uuid = SecureRandom.uuid
    Raven.capture_exception(error, extra: { error_uuid: error_uuid })

    false
  end

  private

  attr_accessor :current_user

  def bgs_service
    return @bgs_service if @bgs_service.present?

    # Set for use by BGSService
    RequestStore.store[:current_user] ||= current_user

    @bgs_service = BGSService.new
  end
end
