# frozen_string_literal: true

class OtherMotionCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::OTHER_MOTION_MAIL_TASK_LABEL
  end

  # if you have a UNIQUE action for the specific task, put it here.
  def available_actions(user)
    return [] unless user

    options = [
      Constants.TASK_ACTIONS.CANCEL_CORRESPONDENCE_TASK.to_h,
      Constants.TASK_ACTIONS.COMPLETE_CORRESPONDENCE_TASK.to_h
    ]

    options
  end
end
