# frozen_string_literal: true

class OtherMotionCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::OTHER_MOTION_MAIL_TASK_LABEL
  end

  # if you have a UNIQUE action for the specific task, put it here.
  # :reek:UtilityFunction
  def available_actions(user)
    return default_actions if user.nil?

    options = if assigned_to.is_a?(User)
                user_actions
              else
                non_user_actions
              end

    options
  end

  private

  def default_actions
    []
  end

  def user_actions
    [
      Constants.TASK_ACTIONS.CANCEL_CORRESPONDENCE_TASK.to_h,
      Constants.TASK_ACTIONS.COMPLETE_CORRESPONDENCE_TASK.to_h,
      Constants.TASK_ACTIONS.REASSIGN_CORR_TASK_TO_PERSON.to_h,
      Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_TEAM.to_h,
      Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h
    ]
  end

  def non_user_actions
    [
      Constants.TASK_ACTIONS.CANCEL_CORRESPONDENCE_TASK.to_h,
      Constants.TASK_ACTIONS.COMPLETE_CORRESPONDENCE_TASK.to_h,
      Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_PERSON.to_h,
      Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_TEAM.to_h,
      Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h
    ]
  end
end
