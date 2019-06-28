# frozen_string_literal: true

class HearingAdminActionVerifyAddressTask < HearingAdminActionTask
  after_update :fetch_closest_ro_and_ahls, if: :task_just_completed?

  def self.label
    "Verify Address"
  end

  def available_hearing_admin_actions(user)
    user_has_access = HearingAdmin.singleton.user_has_access?(user)

    if user_has_access
      [Constants.TASK_ACTIONS.CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE.to_h]
    else
      []
    end
  end

  def update_from_params(params, current_user)
    payload_values = params.delete(:business_payloads)&.dig(:values)

    super(params, current_user) # verifies access

    case params[:status]
    when Constants.TASK_STATUSES.cancelled
      appeal.va_dot_gov_address_validator.assign_ro_and_update_ahls(
        payload_values[:regional_office_value]
      )
    end

    [self]
  end

  private

  def fetch_closest_ro_and_ahls
    appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls
  end

  def task_just_completed?
    saved_change_to_attribute?("status") && status == Constants.TASK_STATUSES.completed
  end
end
