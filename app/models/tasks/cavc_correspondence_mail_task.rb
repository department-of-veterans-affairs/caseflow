# frozen_string_literal: true

class CavcCorrespondenceMailTask < MailTask
  def self.label
    COPY::CAVC_CORRESPONDENCE_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    CavcLitigationSupport.singleton
  end
end
