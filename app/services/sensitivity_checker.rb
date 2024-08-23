# frozen_string_literal: true

class SensitivityChecker
  def initialize(current_user)
    self.current_user = current_user
  end

  def sensitivity_levels_compatible?(user:, veteran:)
    begin
      sensitivity_checker.sensitivity_level_for_user(user) >=
        sensitivity_checker.sensitivity_level_for_veteran(veteran)
    rescue StandardError => error
      error_uuid = SecureRandom.uuid
      Raven.capture_exception(error, extra: { error_uuid: error_uuid })

      false
    end
  end

  private

  attr_accessor :current_user

  def sensitivity_checker
    return @sensitivity_checker if @sensitivity_checker.present?

    # Set for use by BGSService
    RequestStore.store[:current_user] ||= current_user

    @sensitivity_checker = BGSService.new
  end
end
