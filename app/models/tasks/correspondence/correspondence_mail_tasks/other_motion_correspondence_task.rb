# frozen_string_literal: true

class OtherMotionCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::OTHER_MOTION_MAIL_TASK_LABEL
  end

  def available_actions(user)
    options = super
    options.insert(options.length - 1, Constants.TASK_ACTIONS.COR_RETURN_TO_INBOUND_OPS.to_h)
  end
end
