class DistributionTask < GenericTask
  # Prevent this task from being marked complete
  # when a child task (e.g. evidence submission)
  # is marked complete because distribution tasks are used
  # to signal that cases are ready for assignment to judges.
  def update_status_if_children_tasks_are_complete
    if children.any? && children.all? { |t| t.status == Constants.TASK_STATUSES.completed }
      ready_for_distribution!
    end
  end

  def ready_for_distribution!
    update!(status: :assigned, assigned_at: Time.zone.now)
  end

  def ready_for_distribution?
    assigned?
  end

  def ready_for_distribution_at
    assigned_at
  end
end
