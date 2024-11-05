# frozen_string_literal: true

class PowerOfAttorneyRelatedCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::POWER_OF_ATTORNEY_MAIL_TASK_LABEL
  end
end
