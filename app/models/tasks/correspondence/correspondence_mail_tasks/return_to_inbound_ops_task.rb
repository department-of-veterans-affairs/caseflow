# frozen_string_literal: true

# Abstract base class for "tasks not related to an appeal" added to a correspondence during Correspondence Intake.
class ReturnToInboundOpsTask < CorrespondenceMailTask
  def label
    COPY::RETURN_TO_INBOUND_OPS_MAIL_TASK_LABEL
  end
end
