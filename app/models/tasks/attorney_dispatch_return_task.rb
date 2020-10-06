# frozen_string_literal: true

##
# Expected parent task: JudgeDispatchReturnTask

class AttorneyDispatchReturnTask < AttorneyTask
  def self.label
    COPY::ATTORNEY_DISPATCH_RETURN_TASK_LABEL
  end

  def timeline_title
    COPY::CASE_TIMELINE_ATTORNEY_DISPATCH_RETURN_TASK
  end
end
