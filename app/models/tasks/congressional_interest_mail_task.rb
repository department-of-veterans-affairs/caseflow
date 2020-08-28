# frozen_string_literal: true

class CongressionalInterestMailTask < MailTask
  def self.blocking_distribution?
    FeatureToggle.enabled?(:block_at_dispatch) ? false : true
  end

  def self.blocking_dispatch?
    FeatureToggle.enabled?(:block_at_dispatch)
  end

  def self.label
    COPY::CONGRESSIONAL_INTEREST_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    LitigationSupport.singleton
  end
end
