# frozen_string_literal: true

# Task for the CAVC Litigation Support team to clarify the Power of Attorney on a remand before sending the 90 day
# letter to the veteran
class CavcPoaClarificationTask < Task
  def self.label
    COPY::CAVC_POA_TASK_LABEL
  end
end
