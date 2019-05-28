# frozen_string_literal: true

class AttorneyDispatchReturnTask < AttorneyTask
  def label
    COPY::ATTORNEY_DISPATCH_RETURN_TASK_LABEL
  end

  def timeline_title
    COPY::CASE_TIMELINE_ATTORNEY_DISPATCH_RETURN_TASK
  end
end
