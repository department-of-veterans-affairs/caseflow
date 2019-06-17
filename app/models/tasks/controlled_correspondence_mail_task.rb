# frozen_string_literal: true

class ControlledCorrespondenceMailTask < MailTask
  def self.label
    COPY::CONTROLLED_CORRESPONDENCE_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    LitigationSupport.singleton
  end
end
