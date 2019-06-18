# frozen_string_literal: true

module ValidateVsoEmployeeCanAccessFileNumber
  extend ActiveSupport::Concern

  included do
    validate :vso_employee_can_access_file
  end

  private

  def vso_employee_can_access_file
    return unless user.vso_employee?

    errors.add(:workflow, prohibited_error) unless BGSService.new.can_access?(file_number_or_ssn)
    @status = :forbidden
  end

  def prohibited_error
    {
      "title": "Access to Veteran file prohibited",
      "detail": "You do not have access to this claims file number"
    }
  end
end
