# frozen_string_literal: true

class AddressChangeCorrespondenceMailTask < CorrespondenceMailTask
  def self.label
    COPY::ADDRESS_CHANGE_MAIL_TASK_LABEL
  end
end
