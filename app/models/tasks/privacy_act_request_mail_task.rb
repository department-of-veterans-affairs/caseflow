# frozen_string_literal: true

class PrivacyActRequestMailTask < MailTask
  def self.label
    COPY::PRIVACY_ACT_REQUEST_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    PrivacyTeam.singleton
  end

  def self.blocking_dispatch?
    true
  end
end
