# frozen_string_literal: true

class FoiaRequestCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::FOIA_REQUEST_MAIL_TASK_LABEL
  end
end
