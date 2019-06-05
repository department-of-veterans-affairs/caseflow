# frozen_string_literal: true

class FoiaRequestMailTask < MailTask
  def self.blocking?
    true
  end

  def self.label
    COPY::FOIA_REQUEST_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent, _params)
    PrivacyTeam.singleton
  end
end
