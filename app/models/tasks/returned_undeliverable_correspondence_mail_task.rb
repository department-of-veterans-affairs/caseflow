# frozen_string_literal: true

class ReturnedUndeliverableCorrespondenceMailTask < MailTask
  def self.label
    COPY::RETURNED_CORRESPONDENCE_MAIL_TASK_LABEL
  end

  def self.default_assignee(parent)
    return BvaDispatch.singleton if !case_active?(parent)
    return HearingAdmin.singleton if pending_hearing_task?(parent)
    return most_recent_active_task_assignee(parent) if most_recent_active_task_assignee(parent)

    fail Caseflow::Error::MailRoutingError
  end
end
