# frozen_string_literal: true

class CorrespondenceMailTask::FoiaRequestCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::FOIA_REQUEST_MAIL_TASK_LABEL
  end
end
