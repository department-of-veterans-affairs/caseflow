# frozen_string_literal: true

class OpenTasksWithParentNotOnHold < DataIntegrityChecker
  def call
    task_ids = open_tasks_with_parent_not_on_hold.pluck(:id) - ignored_tasks_with_closed_root_task_parent.pluck(:id)
    if task_ids.count > 0
      add_to_report "#{task_ids.count} open " +
                    "task".pluralize(task_ids.count) +
                    " with a non-on_hold parent task (ignoring TrackVeteranTask and *MailTasks)"
      tasks_with_parents = Task.where(id: task_ids).joins(:parent).includes(:parent)
      grouped_tasks = tasks_with_parents.group(:appeal_type, :type, "parents_tasks.type", "parents_tasks.status").count
      add_to_report "Counts: \n#{grouped_tasks.entries.map(&:to_s).join("\n")}"
      add_to_report ONGOING_INVESTIGATIONS
      add_to_report "AMA Appeal ids: #{tasks_with_parents.where(appeal_type: :Appeal).pluck(:appeal_id).uniq.sort}"
    end
  end

  private

  def open_tasks_with_parent_not_on_hold
    Task.open.joins(:parent).includes(:parent).where.not(parents_tasks: { status: :on_hold })
  end

  ONGOING_INVESTIGATIONS = %(
    To investigate, query for open tasks with specific parent type and status; for example:
      HearingTask.open.joins(:parent).includes(:parent).where(parents_tasks: { type: "DistributionTask", status: :assigned })
    For LegacyAppeals, confirm with the Board before modifying tasks.
    For InformalHearingPresentationTask, https://vajira.max.gov/browse/CASEFLOW-2499
    For HearingTask with a parent assigned DistributionTask, https://dsva.slack.com/archives/C3EAF3Q15/p1633041954109500
    For NoShowHearingTask, https://vajira.max.gov/browse/CASEFLOW-2558
    See https://query.prod.appeals.va.gov/question/309-parent-tasks-not-on-hold-with-open-children-tasks
  )

  # It's acceptable to have a closed RootTask parent for these tasks
  IGNORED_TASKS_WITH_CLOSED_ROOTTASK_PARENT ||= [
    # POAs may still want access after an appeal is completed
    # https://dsva.slack.com/archives/C01DFC41BPV/p1634756194393000?thread_ts=1633042678.442600&cid=C01DFC41BPV
    TrackVeteranTask.name, # https://dsva.slack.com/archives/CJL810329/p1634581182080100?thread_ts=1634553075.073600&cid=CJL810329

    # FOIA tasks must be completed regardless of appeal state
    FoiaTask.name, # https://github.com/department-of-veterans-affairs/dsva-vacols/issues/255#issuecomment-992758936

    # Post-dispatch tasks:
    BoardGrantEffectuationTask.name, # https://dsva.slack.com/archives/C2ZAMLK88/p1558555785005300?thread_ts=1558539407.494100&cid=C2ZAMLK88
    VeteranRecordRequest.name, # https://dsva.slack.com/archives/CQTDX9BF0/p1635969424041800?thread_ts=1635968729.041500&cid=CQTDX9BF0

    # Mail can arrive after appeal is dispatched
    *MailTask.descendants.map(&:name) # https://dsva.slack.com/archives/CJL810329/p1634239591067100?thread_ts=1634224678.055200&cid=CJL810329
  ].freeze

  def ignored_tasks_with_closed_root_task_parent
    Task.open.joins(:parent).includes(:parent).where(type: IGNORED_TASKS_WITH_CLOSED_ROOTTASK_PARENT)
      .where(parents_tasks: { type: "RootTask", status: %w[completed cancelled] })
  end
end
