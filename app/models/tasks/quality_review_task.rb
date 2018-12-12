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

  def update_parent_status
    # QualityReviewTasks may be assigned to organizations or individuals. However, for each appeal that goes through
    # quality review the a task assigned to the organization will exist (even if there is none assigned to an
    # individual). To prevent creating duplicate BvaDispatchTasks only create one for the organization task.
    BvaDispatchTask.create_and_assign(root_task) if assigned_to == QualityReview.singleton
    super
  end
end
