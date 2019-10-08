# frozen_string_literal: true

class AttorneyRewriteTask < AttorneyTask
  def self.label
    COPY::ATTORNEY_REWRITE_TASK_LABEL
  end

  def timeline_title
    COPY::CASE_TIMELINE_ATTORNEY_REWRITE_TASK
  end
end
