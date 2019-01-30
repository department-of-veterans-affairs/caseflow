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

  def appeal_data
    # for board grants, filter out request issues
    # that are not the correct business line
    business_line = assigned_to.becomes(BusinessLine)
    request_issues = appeal.request_issues
      .select { |issue| issue.benefit_type == business_line.url }
      .map(&:ui_hash)
    appeal.ui_hash.merge(
      requestIssues: request_issues
    )
  end

  private

  def validate_task
    if completed?
      @error_code = :task_completed
    end

    !@error_code
  end
end
