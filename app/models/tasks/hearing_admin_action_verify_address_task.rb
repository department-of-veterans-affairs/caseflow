# frozen_string_literal: true

class HearingAdminActionVerifyAddressTask < HearingAdminActionTask
  after_update :fetch_closest_ro_and_ahls, if: :task_just_completed?

  def self.label
    "Verify Address"
  end

  def available_hearing_admin_actions(user)
    user_has_access = HearingAdmin.singleton.user_has_access?(user)

    if user_has_access
      [Constants.TASK_ACTIONS.CANCEL_TASK_AND_ASSIGN_REGIONAL_OFFICE.to_h]
    else
      []
    end
  end

  def update_from_params(params, current_user)
    verify_user_can_update!(current_user)

    payload_values = params.delete(:business_payloads)&.dig(:values)

    case params[:status]
    when Constants.TASK_STATUSES.cancelled
      update_ro_and_ahls(payload_values["regional_office_value"])
    end

    super(params, current_user)
  end

  def update_ro_and_ahls(new_ro)
    appeal.update(closest_regional_office: new_ro)
    appeal.va_dot_gov_address_validator.assign_available_hearing_locations_for_ro(regional_office_id: new_ro)
  end

  def fetch_closest_ro_and_ahls
    appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls
  end

  private

  def task_just_completed?
    saved_change_to_attribute?("status") && status == Constants.TASK_STATUSES.completed
  end
end
