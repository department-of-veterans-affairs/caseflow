# frozen_string_literal: true

class HearingAdminActionForeignVeteranCaseTask < HearingAdminActionTask
  def self.label
    "Foreign Veteran case"
  end

  def available_actions(user)
    hearing_admin_actions = available_hearing_user_actions(user)

    [
      Constants.TASK_ACTIONS.PLACE_HOLD.to_h,
      Constants.TASK_ACTIONS.CANCEL_FOREIGN_VETERANS_CASE_TASK.to_h,
      Constants.TASK_ACTIONS.SEND_TO_SCHEDULE_VETERAN_LIST.to_h
    ] | hearing_admin_actions
  end
end
