# frozen_string_literal: true

##
# See https://query.prod.appeals.va.gov/question/309-parent-tasks-not-on-hold-with-open-children-tasks

class OpenTasksWithParentNotOnHold < DataIntegrityChecker
  def call
    task_ids = open_tasks_with_parent_not_on_hold.pluck(:id) - ignored_tasks_with_closed_root_task_parent.pluck(:id)
    if task_ids.count > 0
      add_to_report "#{task_ids.count} open " +
                    "task".pluralize(task_ids.count) +
                    " with a non-on_hold parent task (ignoring TrackVeteranTask and *MailTasks)"
      tasks_with_parents = Task.where(id: task_ids).joins(:parent).includes(:parent)
      grouped_suspect_tasks = tasks_with_parents.group(:type, "parents_tasks.type", "parents_tasks.status").count
      add_to_report "Counts: #{grouped_suspect_tasks.entries.map(&:to_s).join("\n")}"
      add_to_report ONGOING_INVESTIGATIONS
    end
  end

  def slack_channel
    "#appeals-echo"
  end

  private

  def open_tasks_with_parent_not_on_hold
    Task.open.joins(:parent).includes(:parent).where.not(parents_tasks: { status: :on_hold })
  end

  ONGOING_INVESTIGATIONS = %(
    For InformalHearingPresentationTask, https://vajira.max.gov/browse/CASEFLOW-2499
    For HearingTask with a parent assigned DistributionTask, https://dsva.slack.com/archives/C3EAF3Q15/p1633041954109500
    For NoShowHearingTask, https://vajira.max.gov/browse/CASEFLOW-2558
  )

  # It's acceptable to have a closed RootTask parent for:
  # - MailTasks -- https://dsva.slack.com/archives/CJL810329/p1634239591067100?thread_ts=1634224678.055200&cid=CJL810329
  # - TrackVeteranTask -- https://dsva.slack.com/archives/CJL810329/p1634581182080100?thread_ts=1634553075.073600&cid=CJL810329
  IGNORED_TASKS_WITH_CLOSED_ROOTTASK_PARENT = [
    *MailTask.descendants.map(&:name),
    "TrackVeteranTask"
  ].freeze

  def ignored_tasks_with_closed_root_task_parent
    Task.open.joins(:parent).includes(:parent).where(type: IGNORED_TASKS_WITH_CLOSED_ROOTTASK_PARENT)
      .where(parents_tasks: { type: "RootTask", status: %w[completed cancelled] })
  end
end
