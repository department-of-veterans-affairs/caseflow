# frozen_string_literal: true

class EvidenceOrArgumentMailTask < MailTask
  def self.label
    COPY::EVIDENCE_OR_ARGUMENT_MAIL_TASK_LABEL
  end

  def self.default_assignee(parent)
    return Colocated.singleton unless case_active?(parent)

    MailTeam.singleton
  end
end
