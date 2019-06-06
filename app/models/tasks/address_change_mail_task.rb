# frozen_string_literal: true

class AddressChangeMailTask < MailTask
  def self.label
    COPY::ADDRESS_CHANGE_MAIL_TASK_LABEL
  end

  def self.default_assignee(parent)
    fail Caseflow::Error::MailRoutingError unless case_active?(parent)

    return HearingAdmin.singleton if pending_hearing_task?(parent)

    Colocated.singleton
  end
end
