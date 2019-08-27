# frozen_string_literal: true

class AttorneyQualityReviewTask < AttorneyTask
  def self.label
    COPY::ATTORNEY_QUALITY_REVIEW_TASK_LABEL
  end

  def timeline_title
    COPY::CASE_TIMELINE_ATTORNEY_QUALITY_REVIEW_TASK
  end
end
