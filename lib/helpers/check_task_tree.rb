# frozen_string_literal: true

class CheckTaskTree
  def initialize(appeal)
    @appeal = appeal
    @warnings = []
    @errors = []
  end

  def check(verbose: true)
    puts "Checking #{@appeal.class.name} #{@appeal.id} with status: #{@appeal.status.status} ..." if verbose

    @errors << "Open task should not have an on_hold parent task" unless open_tasks_with_parent_not_on_hold.blank?
    @errors << "Closed RootTask should not have open tasks" unless open_tasks_with_closed_root_task.blank?
    @errors << "Open RootTask should have at least one 'proper' active task" if active_tasks_with_open_root_task.blank?
    @errors << "There should be no more than 1 open HearingTask" unless extra_open_hearing_tasks.blank?
    @errors << "There should be no more than 1 open task" unless extra_open_tasks.blank?
    if verbose
      puts("--- ERRORS:", @errors) if @errors.any?
      puts("--- WARNINGS:", @warnings) if @warnings.any?
    end

    [@errors, @warnings]
  end

  def open_tasks_with_parent_not_on_hold
    @appeal.tasks.open.select(&:parent).reject { |task| task.parent&.status == "on_hold" }
  end

  # See AppealsWithClosedRootTaskOpenChildrenQuery
  def open_tasks_with_closed_root_task
    @appeal.tasks.open if @appeal.root_task&.closed?
  end

  # See AppealsWithNoTasksOrAllTasksOnHoldQuery
  IGNORED_ACTIVE_TASKS = %w[RootTask TrackVeteranTask].freeze
  def active_tasks_with_open_root_task
    @appeal.tasks.active.where.not(type: IGNORED_ACTIVE_TASKS) if @appeal.root_task&.open?
  end

  # See AppealsWithMoreThanOneOpenHearingTaskChecker
  def extra_open_hearing_tasks
    hearing_tasks = @appeal.tasks.open.of_type(:HearingTask)
    hearing_tasks.drop 1
  end

  def extra_open_tasks
    hearing_tasks = @appeal.tasks.open.of_type(:HearingTask)
    hearing_tasks.drop 1
  end

  # See DecisionDateChecker
  def request_issues_without_decision_date
    @appeal.request_issues.where
      .not(nonrating_issue_category: nil)
      .where(decision_date: nil, closed_at: nil)
  end
end
