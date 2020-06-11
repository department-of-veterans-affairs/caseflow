# frozen_string_literal: true

class AppealsWithClosedRootTaskOpenChildrenQuery
  def call
    appeals_with_open_child_tasks_and_closed_root_tasks
  end

  private

  def appeals_with_open_child_tasks_and_closed_root_tasks
    Appeal.established.where(id: appeal_ids_for_closed_root_tasks).where(id: appeal_ids_for_open_tasks)
  end

  def appeal_ids_for_closed_root_tasks
    RootTask.closed.select(:appeal_id)
      .where(appeal_type: "Appeal")
  end

  def appeal_ids_for_open_tasks
    Task.open.select(:appeal_id)
      .where(appeal_type: "Appeal")
      .where.not(parent_id: nil)
      .where.not(type: RootTask.name)
  end
end
