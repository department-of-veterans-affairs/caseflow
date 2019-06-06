# frozen_string_literal: true

class ExtensionRequestMailTask < MailTask
  def self.blocking?
    true
  end

  def self.label
    COPY::EXTENSION_REQUEST_MAIL_TASK_LABEL
  end

  def self.default_assignee(parent)
    fail Caseflow::Error::MailRoutingError unless case_active?(parent)

    Colocated.singleton
  end
end
