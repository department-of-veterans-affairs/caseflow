# frozen_string_literal: true

class CongressionalInterestMailTask < MailTask
  def self.blocking?
    true
  end

  def self.label
    COPY::CONGRESSIONAL_INTEREST_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    LitigationSupport.singleton
  end
end
