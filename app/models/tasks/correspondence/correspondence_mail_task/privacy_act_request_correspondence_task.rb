# frozen_string_literal: true

class CorrespondenceMailTask::PrivacyActRequestCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::PRIVACY_ACT_REQUEST_MAIL_TASK_LABEL
  end
end
