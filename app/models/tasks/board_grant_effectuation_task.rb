class BoardGrantEffectuationTask < DecisionReviewTask
  def label
    "Board Grant"
  end

  def serializer_class
    ::WorkQueue::BoardGrantEffectuationTaskSerializer
  end

  def ui_hash
    serializer_class.new(self).as_json
  end

  def complete_with_payload!(_decision_issue_params, _decision_date)
    return false unless validate_task

    update!(status: Constants.TASK_STATUSES.completed, completed_at: Time.zone.now)
  end

  def appeal_ui_hash
    appeal.ui_hash.merge(
      requestIssues: request_issues_by_benefit_type.map(&:ui_hash)
    )
  end

  private

  def request_issues_by_benefit_type
    request_issues = appeal.request_issues
      .select { |issue| issue.benefit_type == business_line.url }
  end

  def business_line
    business_line = assigned_to.becomes(BusinessLine)
  end

  def validate_task
    if completed?
      @error_code = :task_completed
    end

    !@error_code
  end
end
