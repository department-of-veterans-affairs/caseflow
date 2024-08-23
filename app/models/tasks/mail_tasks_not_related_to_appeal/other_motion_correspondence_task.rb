# frozen_string_literal: true

class OtherMotionCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::OTHER_MOTION_MAIL_TASK_LABEL
  end

  def available_actions(user)
    [
      Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_TEAM.to_h
    ]
  end
end
