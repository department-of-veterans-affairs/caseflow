# frozen_string_literal: true

class PrivacyComplaintMailTask < MailTask
  def self.label
    COPY::PRIVACY_COMPLAINT_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    PrivacyTeam.singleton
  end

  def self.blocking_distribution?
    FeatureToggle.enabled?(:block_at_dispatch) ? false : true
  end

  def self.blocking_dispatch?
    FeatureToggle.enabled?(:block_at_dispatch) ? true : false
  end
end
