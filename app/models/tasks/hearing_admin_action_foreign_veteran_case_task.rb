# frozen_string_literal: true

class HearingAdminActionForeignVeteranCaseTask < HearingAdminActionTask
  def self.label
    "Foreign Veteran case"
  end

  def available_actions(user)
    hearing_admin_actions = available_hearing_user_actions(user)

    if (assigned_to &.== user) || HearingsManagement.singleton.user_has_access?(user)
      return [
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.CANCEL_FOREIGN_VETERANS_CASE_TASK.to_h,
        Constants.TASK_ACTIONS.SEND_TO_SCHEDULE_VETERAN_LIST.to_h
      ] | hearing_admin_actions
    end

    hearing_admin_actions
  end

  def update_from_params(params, current_user)
    payload_values = params.delete(:business_payloads)&.dig(:values)

    super(params.except(:instructions), current_user) # verifies access

    parent.update_with_instructions(instructions: params[:instructions])

    case params[:status]
    when Constants.TASK_STATUSES.completed
      appeal.va_dot_gov_address_validator.assign_ro_and_update_ahls(
        payload_values[:regional_office_value]
      )
    end

    [self]
  end
end
