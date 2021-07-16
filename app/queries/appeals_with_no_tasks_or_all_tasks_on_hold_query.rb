# frozen_string_literal: true

class AppealsWithNoTasksOrAllTasksOnHoldQuery
  def call
    [
      appeals_with_only_on_hold_tasks,
      appeals_with_zero_tasks,
      appeals_with_one_task,
      appeals_with_two_tasks_not_distribution,
      appeals_with_fully_on_hold_subtree,
      dispatched_appeals_on_hold
    ].flatten.uniq
  end

  def ama_appeal_stuck?(appeal)
    call.include?(appeal)
  end

  private

  def on_hold
    Constants.TASK_STATUSES.on_hold
  end

  def cancelled
    Constants.TASK_STATUSES.cancelled
  end

  def completed
    Constants.TASK_STATUSES.completed
  end

  def dispatched_appeals_on_hold
    suspect_appeals = Appeal.where(id: tasks_for(Appeal.name)
      .where(type: RootTask.name, status: on_hold))
      .where(id: completed_dispatch_tasks(Appeal.name))

    # Ignore appeals without a decision document as they are not fully dispatched.
    # So return only appeals with a decision document since they are successfully dispatched.
    suspect_appeals.select(&:decision_document)
  end

  def completed_dispatch_tasks(klass_name)
    tasks_for(klass_name).where(type: [BvaDispatchTask.name], status: completed)
  end

  def appeals_with_zero_tasks
    Appeal.established.left_outer_joins(:tasks).where(tasks: { id: nil })
  end

  def appeals_with_one_task
    Appeal.established.active.joins(:tasks).group("appeals.id").having("count(tasks) = 1")
  end

  def appeals_with_two_tasks_not_distribution
    Appeal.established.active
      .joins(:tasks)
      .group("appeals.id")
      .having("count(tasks) = 2 AND count(case when tasks.type = ? then 1 end) = 0", DistributionTask.name)
  end

  # Confirm that all subtrees have an active task
  def appeals_with_fully_on_hold_subtree
    Appeal.where(id:
      Task.left_outer_joins(:children).on_hold
        .where.not(type: [RootTask.name, TrackVeteranTask.name, EvidenceSubmissionWindowTask.name, TimedHoldTask.name])
        .group("tasks.id")
        .having(
          "count(case when children_tasks.status in (?) then 1 end) = 0",
          Task.open_statuses
        ).select(:appeal_id).distinct)
  end

  def tasks_for(klass_name)
    Task.select(:appeal_id).where(appeal_type: klass_name)
  end

  def appeals_with_only_on_hold_tasks
    Appeal.established.active
      .joins(:tasks)
      .group("appeals.id")
      .having(
        "count(case when tasks.status in (?) AND tasks.type != 'TrackVeteranTask' then 1 end)" \
        " = count(case when tasks.status = ? AND tasks.type != 'TrackVeteranTask' then 1 end)",
        Task.open_statuses,
        on_hold
      )
  end
end
