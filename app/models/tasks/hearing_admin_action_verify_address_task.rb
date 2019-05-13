class HearingAdminActionVerifyAddressTask < HearingAdminActionTask
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
    payload_values = params.delete(:business_payloads)&.dig(:values)
    
    if params[:status] == Constants.TASK_STATUSES.completed
      fetch_closest_ro_and_ahls
    elsif params[:status] == Constants.TASK_STATUSES.cancelled
      update_ro_and_ahls(payload_values["regional_office_value"])

      # TODO push to end of instructions
      update(instructions: [payload_values["notes_value"]])
    end

    super(params, current_user)
  end

  def update_ro_and_ahls(new_ro)
    appeal.update(closest_regional_office: new_ro)

    # ro = # Get RO

    # appeal.va_dot_gov_address_validator.create_available_hearing_locations_from_ro(ro: ro)
  end

  def fetch_closest_ro_and_ahls
    appeal.va_dot_gov_address_validator.update_closest_ro_and_ahls
  end
end
