# frozen_string_literal: true

class DeathCertificateMailTask < MailTask
  def self.label
    COPY::DEATH_CERTIFICATE_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    Colocated.singleton
  end
end
