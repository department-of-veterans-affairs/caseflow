# frozen_string_literal: true

class AddressVerificationColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.address_verification
  end
end
