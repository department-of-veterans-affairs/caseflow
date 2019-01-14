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
    return false unless validate

    update!(status: Constants.TASK_STATUSES.completed, completed_at: Time.zone.now)
  end

  private

  def validate
    if !in_progress?
      @error_code = :task_not_in_progress
    end

    !@error_code
  end
end
