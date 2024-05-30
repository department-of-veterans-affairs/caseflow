# frozen_string_literal: true

class VacolsUpdatedMailTask < CorrespondenceTask
  def self.label
    COPY::VACOLS_UPDATED_MAIL_TASK_LABEL
  end
end
