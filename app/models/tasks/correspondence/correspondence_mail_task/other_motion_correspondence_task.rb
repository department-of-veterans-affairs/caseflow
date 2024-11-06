# frozen_string_literal: true

class CorrespondenceMailTask::OtherMotionCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::OTHER_MOTION_MAIL_TASK_LABEL
  end
end
