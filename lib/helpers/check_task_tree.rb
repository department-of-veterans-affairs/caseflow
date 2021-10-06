# frozen_string_literal: true

class CheckTaskTree
  def initialize(appeal)
    @appeal = appeal
    @warnings = []
    @errors = []
  end

  def check
    puts "Checking #{@appeal.class.name} #{@appeal.id} ..."

    @errors << "Open task should not have an on_hold parent task" if open_tasks_with_parent_not_on_hold
    @errors << "Closed parent task should not have an open child task" if open_tasks_with_closed_parent
    @errors << "Closed RootTask should not have open tasks" if open_tasks_with_closed_root_task.any?
    pp active_tasks
    pp appeal_status
    @errors << "There should be no more than 1 open HearingTask" if open_hearing_tasks.count > 1

    puts("--- ERRORS:", @errors) if @errors.any?
    puts("--- WARNINGS:", @warnings) if @warnings.any?

    [@errors, @warnings]
  end

  def open_tasks_with_parent_not_on_hold
    @appeal.tasks.open.map(&:status)
  end

  # See AppealsWithClosedRootTaskOpenChildrenQuery
  def open_tasks_with_closed_root_task
    if @appeal.root_task&.closed?
      @appeal.tasks.open.map(&:status)
    else
      @appeal.tasks.open.map(&:status)
    end
  end

  def open_tasks_with_closed_parent
  end

  # See AppealsWithNoTasksOrAllTasksOnHoldQuery
  def active_tasks
    @appeal.tasks.active
  end

  def appeal_status
    @appeal.status.status == :unknown
  end

  # See AppealsWithMoreThanOneOpenHearingTaskChecker
  def open_hearing_tasks
    []
  end

  # See DecisionDateChecker
  def request_issues_without_decision_date
    @appeal.request_issues.where
      .not(nonrating_issue_category: nil)
      .where(decision_date: nil, closed_at: nil)
  end
end
