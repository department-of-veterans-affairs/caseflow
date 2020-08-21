# frozen_string_literal: true

class FoiaRequestMailTask < MailTask
  def self.label
    COPY::FOIA_REQUEST_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    PrivacyTeam.singleton
  end

  def self.blocking_dispatch?
    true
  end
end
