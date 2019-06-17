# frozen_string_literal: true

class StatusInquiryMailTask < MailTask
  def self.label
    COPY::STATUS_INQUIRY_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    LitigationSupport.singleton
  end
end
