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
    update!(status: Constants.TASK_STATUSES.completed, completed_at: Time.zone.now)
  end
end
