# frozen_string_literal: true

##
# See https://query.prod.appeals.va.gov/question/309-parent-tasks-not-on-hold-with-open-children-tasks

class OpenTasksWithParentNotOnHold < DataIntegrityChecker
  def call
    suspect_tasks = open_tasks_with_parent_not_on_hold
    if suspect_tasks.count > 0
      add_to_report "#{suspect_tasks.count} open " +
                    "task".pluralize(suspect_tasks.count) +
                    " with non-on_hold parent task"
      add_to_report "Counts: #{suspect_tasks.group(:type, 'parents_tasks.type', 'parents_tasks.status').count}"
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
end
