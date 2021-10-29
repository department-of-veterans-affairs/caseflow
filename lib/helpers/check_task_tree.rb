# frozen_string_literal: true

##
# Checks for invalid task trees, which could cause an appeal to become stuck or be processed incorrectly.
# An invalid task tree is one that does not conform to our expectations of typical task trees
# or to scenarios that the code expects.
#
# We have background jobs that check for bad invalid trees, but the alerts are sometimes overwhelming and
# engineers may not address the problem in time (i.e., before the appeal is dispatched).
#
# Engineers should run this class before and after they modify a task tree:
# `check_task_tree(appeal)` or `CheckTaskTree.call(appeal)` or
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

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def check(verbose: true)
    puts "Checking #{@appeal.class.name} #{@appeal.id} with status: #{@appeal.status.status} ..." if verbose

    check_task_attributes
    check_parent_child_tasks
    check_task_counts
    check_task_prerequisites

    # Associated records
    @errors << "Task should be closed since there are no active issues" unless open_tasks_with_no_active_issues.blank?
    @errors << "Closed task should not have processable TaskTimer" unless open_task_timers_for_closed_tasks.blank?

    @errors << "Appeal is stuck" if @appeal.try(:stuck?)

    if verbose
      puts("--- ERRORS:", @errors) if @errors.any?
      puts("--- WARNINGS:", @warnings) if @warnings.any?
    end

    [@errors, @warnings]
  end

  def check_task_attributes
    @errors << "Open task should have nil `closed_at`" unless open_tasks_with_closed_at_defined.blank?
    @errors << "Closed task should have non-nil `closed_at`" unless closed_tasks_without_closed_at.blank?

    @errors << "Open task should have nil `cancelled_by_id`" unless open_tasks_with_cancelled_by_defined.blank?
    @errors << "Cancelled task should have non-nil `cancelled_by_id`" unless cancelled_tasks_without_cancelled_by.blank?

    @errors << "Open task should not be assigned to inactive assignee" unless open_tasks_with_inactive_assignee.blank?
    unless inconsistent_assignees.blank?
      @errors << "Task assignee is inconsistent with other tasks of the same type: #{inconsistent_assignees}"
    end
    unless track_veteran_task_assigned_to_non_representative.blank?
      @errors << "TrackVeteranTask assignee should be a Representative (i.e., VSO or PrivateBar)"
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def check_parent_child_tasks
    @errors << "Open task should have an on_hold parent task" unless open_tasks_with_parent_not_on_hold.blank?

    @errors << "Closed RootTask should not have open tasks" unless open_tasks_with_closed_root_task.blank?

    if active_tasks_with_open_root_task&.empty?
      @errors << "Open RootTask should have an active task assigned to the Board"
    end
  end

  def check_task_counts
    @errors << "There should be no more than 1 open HearingTask" unless extra_open_hearing_tasks.blank?
    @errors << "There should be no more than 1 open task of type #{extra_open_tasks}" unless extra_open_tasks.blank?
    unless extra_open_org_tasks.blank?
      @errors << "There should be no more than 1 open org task of type #{extra_open_org_tasks}"
    end
  end

  def check_task_prerequisites
    unless missing_dispatch_task_prerequisite.blank?
      @errors << "BvaDispatchTask requires #{missing_dispatch_task_prerequisite}"
    end
  end

  # See OpenTasksWithClosedAtChecker
  def open_tasks_with_closed_at_defined
    @appeal.tasks.open.where.not(closed_at: nil)
  end

  def closed_tasks_without_closed_at
    @appeal.tasks.closed.where(closed_at: nil)
  end

  def open_tasks_with_cancelled_by_defined
    @appeal.tasks.open.where.not(cancelled_by_id: nil)
  end

  def cancelled_tasks_without_cancelled_by
    @appeal.tasks.cancelled.where(cancelled_by_id: nil)
  end

  def open_tasks_with_inactive_assignee
    @appeal.tasks.open.where(assigned_to: User.inactive) +
      @appeal.tasks.open.where(assigned_to: Organization.unscoped.inactive)
  end

  def inconsistent_assignees
    tasks_with_unexpected_assignee.pluck(:type, :assigned_to_type, :assigned_to_id)
  end

  # Don't use a constant for this hash as that could initialize the assignees before the DB is ready
  # To check in prod: `DistributionTask.group(:appeal_type, :assigned_to_type, :assigned_to_id).count`
  def expected_assignee_hash
    @expected_assignee_hash ||= {
      # These are always assigned to the BVA org
      RootTask => Bva.singleton,
      DistributionTask => Bva.singleton,
      HearingTask => Bva.singleton,
      CavcTask => Bva.singleton,

      # Only for AMA. `ScheduleHearingTask.group(:appeal_type, :assigned_to_type, :assigned_to_id).count`
      ScheduleHearingTask.ama => Bva.singleton,

      # Only for tasks assigned to an Organization.
      # e.g., `TranscriptionTask.assigned_to_any_org.group(:appeal_type, :assigned_to_type, :assigned_to_id).count`
      TranscriptionTask.assigned_to_any_org => TranscriptionTeam.singleton,
      BvaDispatchTask.assigned_to_any_org => BvaDispatch.singleton,
      QualityReviewTask.assigned_to_any_org => QualityReview.singleton,
      FoiaTask.assigned_to_any_org => PrivacyTeam.singleton
    }
  end

  def tasks_with_unexpected_assignee
    expected_assignee_hash.map do |task_query, assignee|
      task_query.where(appeal: @appeal).reject { |task| task.assigned_to == assignee }
    end.select(&:any?).flatten
  end

  # `Organization.unscoped{TrackVeteranTask.includes(:assigned_to).reject{|task| task.assigned_to.is_a?(Representative)}}`
  def track_veteran_task_assigned_to_non_representative
    Organization.unscoped do
      TrackVeteranTask.where(appeal: @appeal).reject { |task| task.assigned_to.is_a?(Representative) }
    end
  end

  def open_tasks_with_parent_not_on_hold
    tasks_with_parents.open.reject { |task| task.parent&.status == "on_hold" }
  end

  # See AppealsWithClosedRootTaskOpenChildrenQuery
  def open_tasks_with_closed_root_task
    tasks_with_parents.open if @appeal.root_task&.closed?
  end

  # Task types that are ignored when checking that an appeal is not stuck
  IGNORED_ACTIVE_TASKS = %w[TrackVeteranTask].freeze
  # Detects one of the problems from AppealsWithNoTasksOrAllTasksOnHoldQuery
  # Should also emcompass OpenHearingTasksWithoutActiveDescendantsChecker
  def active_tasks_with_open_root_task
    tasks_with_parents.active.where.not(type: IGNORED_ACTIVE_TASKS) if @appeal.root_task&.open?
  end

  # See AppealsWithMoreThanOneOpenHearingTaskChecker
  def extra_open_hearing_tasks
    hearing_tasks = @appeal.tasks.open.of_type(:HearingTask)
    hearing_tasks.drop 1
  end

  # Task types where only one should be open at a time.
  # Some of these have Rails validations to prevent more than 1 open of the task type
  # but the validations can be subverted, so let's check them here just in case.
  # https://department-of-veterans-affairs.github.io/caseflow/task_trees/trees/tasks-overview.html
  # Example: https://github.com/department-of-veterans-affairs/dsva-vacols/issues/217#issuecomment-906779760
  SINGULAR_OPEN_TASKS = %w[RootTask DistributionTask
                           HearingTask ScheduleHearingTask AssignHearingDispositionTask ChangeHearingDispositionTask
                           JudgeAssignTask JudgeDecisionReviewTask
                           AttorneyTask AttorneyRewriteTask
                           JudgeQualityReviewTask AttorneyQualityReviewTask
                           JudgeDispatchReturnTask AttorneyDispatchReturnTask
                           VeteranRecordRequest].freeze
  SINGULAR_OPEN_ORG_TASKS = %w[
    QualityReviewTask
    BvaDispatchTask
  ].freeze
  def extra_open_tasks
    @appeal.tasks.select(:type).open.of_type(SINGULAR_OPEN_TASKS).group(:type).having("count(*) > 1").count
  end

  def extra_open_org_tasks
    @appeal.tasks.select(:type).open.assigned_to_any_org.of_type(SINGULAR_OPEN_ORG_TASKS)
      .group(:type).having("count(*) > 1").count
  end

  # See DecisionReviewTasksForInactiveAppealsChecker
  def open_tasks_with_no_active_issues
    has_active_issues = @appeal.request_issues.active.any?
    return if has_active_issues

    # Ignoring BoardGrantEffectuationTask (which can stay open with all issues decided),
    # find all open tasks assigned to a BusinessLine
    @appeal.tasks.open.assigned_to_any_org.where(assigned_to_id: BusinessLine.pluck(:id))
      .reject { |task| task.type == "BoardGrantEffectuationTask" }
  end

  # See PendingIncompleteAndUncancelledTaskTimersChecker
  def open_task_timers_for_closed_tasks
    TaskTimer.processable.where(task: @appeal.tasks.closed)
  end

  # BvaDispatchTask should not be open if there is no completed JudgeDecisionReviewTask task
  def missing_dispatch_task_prerequisite
    dispatch_task = @appeal.tasks.open.find_by_type(:BvaDispatchTask)
    return unless dispatch_task

    missing = []
    jdr_task = @appeal.tasks.completed.find_by_type(:JudgeDecisionReviewTask)
    missing << "completed JudgeDecisionReviewTask" unless jdr_task

    missing
  end

  private

  def tasks_with_parents
    @appeal.tasks.where.not(parent_id: nil)
  end
end
