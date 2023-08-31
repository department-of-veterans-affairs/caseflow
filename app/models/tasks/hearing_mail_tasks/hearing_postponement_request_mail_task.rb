# frozen_string_literal: true

##
# Task to process a hearing postponement request received via the mail
#
# When this task is created:
#   - It's parent task is set as the RootTask of the associated appeal
#   - The task is assigned to the MailTeam to track where the request originated
#   - A child task of the same name is created and assigned to the HearingAdmin organization
##
class HearingPostponementRequestMailTask < HearingRequestMailTask
  class << self
    def label
      COPY::HEARING_POSTPONEMENT_REQUEST_MAIL_TASK_LABEL
    end

    def allow_creation?(*)
      true
    end
  end

  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
    Constants.TASK_ACTIONS.COMPLETE_AND_POSTPONE.to_h,
    Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
    Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
    Constants.TASK_ACTIONS.CANCEL_TASK.to_h
  ].freeze

  def available_actions(user)
    return [] unless user.in_hearing_admin_team?

    if active_schedule_hearing_task? || open_assign_hearing_disposition_task?
      TASK_ACTIONS
    else
      [
        Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end
  end
end
