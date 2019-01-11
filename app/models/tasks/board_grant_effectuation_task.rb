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

  def complete!
    update!(status: Constants.TASK_STATUSES.completed, completed_at: Time.zone.now)
  end
end
