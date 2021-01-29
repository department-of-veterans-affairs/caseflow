# frozen_string_literal: true

class AppealsWithCancelledRootTaskCompletedDispatchQuery
  def call
    appeals_with_cancelled_root_tasks_and_completed_child_dispatch_task
  end

  private

  def appeals_with_cancelled_root_tasks_and_completed_child_dispatch_task
    Appeal.established.where(id: appeal_ids_for_cancelled_root_tasks).where(id: appeal_ids_for_completed_dispatch_tasks)
  end

  def appeal_ids_for_cancelled_root_tasks
    RootTask.cancelled.select(:appeal_id).where(appeal_type: "Appeal")
  end

  def appeal_ids_for_completed_dispatch_tasks
    BvaDispatchTask.completed.select(:appeal_id).where(appeal_type: "Appeal")
  end
end
