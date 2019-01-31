class BoardGrantEffectuationTask < DecisionReviewTask
  include BusinessLineTask

  def label
    "Board Grant"
  end

  def serializer_class
    ::WorkQueue::BoardGrantEffectuationTaskSerializer
  end

  def appeal_ui_hash
    appeal.ui_hash.merge(
      requestIssues: request_issues_by_benefit_type.map(&:ui_hash)
    )
  end

  private

  def request_issues_by_benefit_type
    appeal.request_issues
      .select { |issue| issue.benefit_type == business_line.url }
  end
end
