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

  ## Tag to determine if this task is considered a blocking task for Legacy Appeal Distribution
  def self.legacy_blocking?
    true
  end
end
