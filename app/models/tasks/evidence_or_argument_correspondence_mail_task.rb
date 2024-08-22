# frozen_string_literal: true

class EvidenceOrArgumentCorrespondenceMailTask < CorrespondenceMailTask
  def self.label
    COPY::EVIDENCE_OR_ARGUMENT_MAIL_TASK_LABEL
  end
end
