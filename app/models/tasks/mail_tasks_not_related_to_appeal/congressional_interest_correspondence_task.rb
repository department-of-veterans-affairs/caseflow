# frozen_string_literal: true

class CongressionalInterestCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::CONGRESSIONAL_INTEREST_MAIL_TASK_LABEL
  end
end
