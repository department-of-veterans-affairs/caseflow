# frozen_string_literal: true

class CheckTaskTree
  def initialize(appeal)
    @appeal = appeal
    @warnings = []
    @errors = []
  end

  # :reek:BooleanParameter
  def check(verbose: true)
    puts "Checking #{@appeal.class.name} #{@appeal.id} with status: #{@appeal.status.status} ..." if verbose

    check_parent_child_tasks
    check_task_counts

    if verbose
      puts("--- ERRORS:", @errors) if @errors.any?
      puts("--- WARNINGS:", @warnings) if @warnings.any?
    end

    [@errors, @warnings]
  end

  def check_parent_child_tasks
    @errors << "Open task should have an on_hold parent task" unless open_tasks_with_parent_not_on_hold.blank?

    @errors << "Closed RootTask should not have open tasks" unless open_tasks_with_closed_root_task.blank?
    @errors << "Open RootTask should have at least one 'proper' active task" if active_tasks_with_open_root_task.blank?
  end

  def check_task_counts
    @errors << "There should be no more than 1 open HearingTask" unless extra_open_hearing_tasks.blank?
    @errors << "There should be no more than 1 open task of type #{extra_open_tasks}" unless extra_open_tasks.blank?
  end

  def open_tasks_with_parent_not_on_hold
    @appeal.tasks.open.select(&:parent).reject { |task| task.parent&.status == "on_hold" }
  end

  # See AppealsWithClosedRootTaskOpenChildrenQuery
  def open_tasks_with_closed_root_task
    @appeal.tasks.open if @appeal.root_task&.closed?
  end

  # Task types that are ignored when checking that an appeal is not stuck
  IGNORED_ACTIVE_TASKS = %w[RootTask TrackVeteranTask].freeze
  # See AppealsWithNoTasksOrAllTasksOnHoldQuery
  def active_tasks_with_open_root_task
    @appeal.tasks.active.where.not(type: IGNORED_ACTIVE_TASKS) if @appeal.root_task&.open?
  end

  # See AppealsWithMoreThanOneOpenHearingTaskChecker
  def extra_open_hearing_tasks
    hearing_tasks = @appeal.tasks.open.of_type(:HearingTask)
    hearing_tasks.drop 1
  end

  # Task types where only one should be open at a time
  SINGULAR_OPEN_TASKS = %w[RootTask DistributionTask
                           HearingTask ScheduleHearingTask AssignHearingDispositionTask ChangeHearingDispositionTask
                           JudgeAssignTask JudgeDecisionReviewTask
                           AttorneyTask AttorneyRewriteTask
                           JudgeQualityReviewTask AttorneyQualityReviewTask
                           JudgeDispatchReturnTask AttorneyDispatchReturnTask
                           VeteranRecordRequest].freeze
  def extra_open_tasks
    @appeal.tasks.select(:type).open.of_type(SINGULAR_OPEN_TASKS).group(:type).having("count(*) > 1").count
  end

  # See DecisionDateChecker
  def request_issues_without_decision_date
    @appeal.request_issues.where
      .not(nonrating_issue_category: nil)
      .where(decision_date: nil, closed_at: nil)
  end
end
