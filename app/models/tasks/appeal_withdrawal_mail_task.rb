# frozen_string_literal: true

class AppealWithdrawalMailTask < MailTask
  def self.label
    COPY::APPEAL_WITHDRAWAL_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    BvaIntake.singleton
  end
end
