# frozen_string_literal: true

class SentToRojMailTask < MailTask
  def self.label
    COPY::SENT_TO_ROJ_MAIL_TASK_LABEL
  end
end
