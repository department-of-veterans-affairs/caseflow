# frozen_string_literal: true

class CavcCorrespondenceCorrespondenceTask < CorrespondenceMailTask

  def label
    COPY::FOIA_REQUEST_MAIL_TASK_LABEL
  end
end
