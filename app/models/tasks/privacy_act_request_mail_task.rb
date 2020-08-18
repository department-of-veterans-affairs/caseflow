# frozen_string_literal: true

class PrivacyActRequestMailTask < MailTask
  def self.blocking?
    true
  end

  def self.label
    COPY::PRIVACY_ACT_REQUEST_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    PrivacyTeam.singleton
  end

  def blocks_dispatch?
    return false unless FeatureToggle.enabled?(:cm_move_with_blocking_tasks)
    true
  end
end
