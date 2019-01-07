class DecisionReviewTask < GenericTask
  def label
    appeal_type.constantize.review_title
  end

  def serializer_class
    ::WorkQueue::DecisionReviewTaskSerializer
  end

  def ui_hash
    serializer_class.new(self).as_json
  end

  def complete(decision_issue_params)
    transaction do
      appeal.create_decision_issues_for_tasks(decision_issue_params)
      update!(status: Constants.TASK_STATUSES.completed, completed_at: Time.zone.now)
    end
  end
end
