# frozen_string_literal: true

##
# Checks for invalid task trees, which could cause an appeal to become stuck or be processed incorrectly.
# An invalid task tree is one that does not conform to our expectations of typical task trees
# or to scenarios that the code expects.
#
# We have background jobs that check for bad invalid trees, but the alerts are sometimes overwhelming and
# engineers may not address the problem in time (i.e., before the appeal is dispatched).
#
# Engineers should run this class after they modify a task tree: `check_task_tree(appeal)` or `CheckTaskTree.call(appeal)` or
# ```
#   CheckTaskTree.patch_classes
#   appeal.check_task_tree
# ```
# It will show problems with the task tree so the engineer can immediately remedy them
# and prevent downstream appeal processing problems.
#
# Get more details and list specific problems by calling specific methods like so:
# ```
#   ctt = CheckTaskTree.new(appeal)
#   errors, warnings = ctt.check
#   ctt.open_tasks_with_parent_not_on_hold
# ```

class CheckTaskTree
  module TaskTreeCheckable
    def check_task_tree(verbose: true)
      CheckTaskTree.call(self, verbose: verbose)
    end
  end

  class << self
    def call(appeal, verbose: true)
      CheckTaskTree.new(appeal).check(verbose: verbose)
    end

    def patch_classes
      Appeal.include TaskTreeCheckable
    end
  end

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

    @errors << "Appeal is stuck" if @appeal.try(:stuck?)

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
  # Detects one of the problems from AppealsWithNoTasksOrAllTasksOnHoldQuery
  def active_tasks_with_open_root_task
    @appeal.tasks.active.where.not(type: IGNORED_ACTIVE_TASKS) if @appeal.root_task&.open?
  end

  # See AppealsWithMoreThanOneOpenHearingTaskChecker
  def extra_open_hearing_tasks
    hearing_tasks = @appeal.tasks.open.of_type(:HearingTask)
    hearing_tasks.drop 1
  end

  # Task types where only one should be open at a time.
  # Some of these have Rails validations to prevent more than 1 open of the task type
  # but the validations can be subverted, so let's check them here just in case.
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
