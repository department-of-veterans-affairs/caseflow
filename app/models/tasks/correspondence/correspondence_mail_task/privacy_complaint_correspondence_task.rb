# frozen_string_literal: true

class CorrespondenceMailTask::PrivacyComplaintCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::PRIVACY_COMPLAINT_MAIL_TASK_LABEL
  end
end
