# frozen_string_literal: true

class CorrespondenceMailTask::AddressChangeCorrespondenceMailTask < CorrespondenceMailTask
  def self.label
    COPY::ADDRESS_CHANGE_MAIL_TASK_LABEL
  end
end
