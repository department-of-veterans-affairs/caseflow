# frozen_string_literal: true

class OpenTasksWithClosedAtChecker < DataIntegrityChecker
  def call
    suspect_tasks = open_tasks_with_closed_at_defined
    if suspect_tasks.count > 0
      add_to_report "#{suspect_tasks.count} open " + "Task".pluralize(suspect_tasks.count) + " with a closed_at value"
      add_to_report "Verify data error with `Task.open.where.not(closed_at: nil)`"
      add_to_report "These tasks likely were manually re-opened and should have closed_at set to NULL"
    end

    suspect_task_ids = open_tasks_with_closed_parent.pluck(:id) - ignored_tasks_with_closed_root_task_parent.pluck(:id)
    if suspect_task_ids.count > 0
      add_to_report "#{suspect_task_ids.count} open " +
                    "Task".pluralize(suspect_task_ids.count) +
                    " with a closed parent Task"
      add_to_report "Counts: " + Task.where(id: suspect_task_ids).group(:type).count.to_s
      add_to_report "Verify with `Task.where(id: [#{suspect_task_ids.join(',')}])`"
    end
  end

  def slack_channel
    "#appeals-echo"
  end

  private

  def open_tasks_with_closed_at_defined
    Task.open.where.not(closed_at: nil)
  end

  def open_tasks_with_closed_parent
    Task.open.joins(:parent).includes(:parent).where.not(parents_tasks: { closed_at: nil })
  end

  # It's acceptable to have a closed RootTask parent for:
  # - MailTasks -- https://dsva.slack.com/archives/CJL810329/p1634239591067100?thread_ts=1634224678.055200&cid=CJL810329
  # - TrackVeteranTask -- https://dsva.slack.com/archives/CJL810329/p1634581182080100?thread_ts=1634553075.073600&cid=CJL810329
  IGNORED_TASKS_WITH_CLOSED_ROOTTASK_PARENT = MailTask.descendants.map(&:name) + ["TrackVeteranTask"]
  def ignored_tasks_with_closed_root_task_parent
    Task.open.joins(:parent).includes(:parent).where(type: IGNORED_TASKS_WITH_CLOSED_ROOTTASK_PARENT).where(parents_tasks: { type: "RootTask", status: %w[completed cancelled] })
  end
end
