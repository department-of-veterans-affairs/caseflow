# frozen_string_literal: true

class OtherMotionCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::OTHER_MOTION_MAIL_TASK_LABEL
  end

  # if you have a UNIQUE action for the specific task, put it here.

  def available_actions(_user)
    if assigned_to.is_a?(User)
      [
        Constants.TASK_ACTIONS.REASSIGN_CORR_TASK_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.CANCEL_CORRESPONDENCE_TASK.to_h
      ]
    else
      [
        Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.CANCEL_CORRESPONDENCE_TASK.to_h
      ]
    end
  end
end
