# frozen_string_literal: true

class OtherMotionCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::OTHER_MOTION_MAIL_TASK_LABEL
  end

  def available_actions(user)
    return [] unless user_can_work_task_correspondence_mail_task(user)

    options = super
    options.insert(options.length, Constants.TASK_ACTIONS.COR_RETURN_TO_INBOUND_OPS.to_h)
  end
end
