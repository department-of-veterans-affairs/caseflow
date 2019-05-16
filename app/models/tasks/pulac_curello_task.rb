# frozen_string_literal: true

class PulacCurelloTask < GenericTask
  # Skip unique verification
  def verify_org_task_unique; end

  def label
    Constants.LIT_SUPPORT.PULAC_CURELLO
  end
end 