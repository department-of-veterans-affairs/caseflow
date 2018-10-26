class QualityReviewTask < GenericTask
  def available_actions(user)
    return super if assigned_to != user

    [
      Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
      Constants.TASK_ACTIONS.RETURN_TO_JUDGE.to_h
    ]
  end

  def self.create_from_root_task(root_task)
    create!(assigned_to: QualityReview.singleton, parent_id: root_task.id, appeal: root_task.appeal)
  end

  def mark_as_complete!
    BvaDispatchTask.create_and_assign(root_task)
    super
  end
end
