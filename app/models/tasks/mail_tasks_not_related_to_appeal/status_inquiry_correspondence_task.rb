# frozen_string_literal: true

class StatusInquiryCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::STATUS_INQUIRY_MAIL_TASK_LABEL
  end
end