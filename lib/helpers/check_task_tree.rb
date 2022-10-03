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

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
  def check(verbose: true)
    unless @appeal.is_a?(Appeal)
      puts "This checker is only for AMA appeals"
      return
    end

    puts "Checking #{@appeal.class.name} #{@appeal.id} with status: #{status} ..." if verbose

    check_task_attributes
    check_parent_child_tasks
    check_task_counts
    check_task_prerequisites

    # Associated records
    @errors << "Task should be closed since there are no active issues" unless open_tasks_with_no_active_issues.blank?
    @errors << "Closed task should not have processable TaskTimer" unless open_task_timers_for_closed_tasks.blank?

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

  def check_parent_child_tasks
    @errors << "Open task should have an on_hold parent task" unless open_tasks_with_parent_not_on_hold.blank?

    @errors << "Closed RootTask should not have open tasks" unless open_tasks_with_closed_root_task.blank?

    if active_tasks_with_open_root_task&.empty?
      @errors << "Open RootTask should have an active task assigned to the Board"
    end

    unless unexpected_child_tasks.blank?
      @errors << "Unexpected child task: #{unexpected_child_tasks.pluck(:type, :id)}"
    end
    unless tasks_with_unexpected_parent_task.blank?
      @errors << "Unexpected parent task for: #{tasks_with_unexpected_parent_task.pluck(:type, :id)}"
    end
  end

  def check_task_counts
    # See AppealsWithNoTasksOrAllTasksOnHoldQuery
    @errors << "There should be at least 1 task" if @appeal.tasks.count == 0
    @errors << "Active appeal should have at least 1 non-RootTask task" if @appeal.active? && @appeal.tasks.count == 1

    distribution_task = @appeal.tasks.find_by_type(:DistributionTask)
    @errors << "Established appeal should have a DistributionTask" if @appeal.established_at? && distribution_task.nil?

    if open_root_task_for_dispatched_appeal?
      @errors << "Dispatched appeal (with decision document) should not have open RootTask"
    end

    @errors << "There should be no more than 1 open HearingTask" unless extra_open_hearing_tasks.blank?
    @errors << "There should be no more than 1 open task of type #{extra_open_tasks}" unless extra_open_tasks.blank?
    unless extra_open_org_tasks.blank?
      @errors << "There should be no more than 1 open org task of type #{extra_open_org_tasks}"
    end
    if open_exclusive_root_children_tasks.count > 1
      open_task_types = open_exclusive_root_children_tasks.pluck(:type, :id)
      @errors << "There should be no more than 1 open among these root-children tasks: #{open_task_types}"
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize

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

  # Organization.unscoped{TrackVeteranTask.includes(:assigned_to).reject do |task|
  #    task.assigned_to.is_a?(Representative)}
  # end
  def track_veteran_task_assigned_to_non_representative
    Organization.unscoped do
      TrackVeteranTask.where(appeal: @appeal).reject { |task| task.assigned_to.is_a?(Representative) }
    end
  end

  # See OpenTasksWithParentNotOnHold
  def open_tasks_with_parent_not_on_hold
    child_tasks.open.reject { |task| task.parent&.status == "on_hold" }
  end

  # See AppealsWithClosedRootTaskOpenChildrenQuery
  def open_tasks_with_closed_root_task
    child_tasks.open if @appeal.root_task&.closed?
  end

  # Task types that are ignored when checking that an appeal is not stuck
  IGNORED_ACTIVE_TASKS ||= %w[TrackVeteranTask].freeze
  # Detects one of the problems from AppealsWithNoTasksOrAllTasksOnHoldQuery
  # Should also emcompass OpenHearingTasksWithoutActiveDescendantsChecker
  def active_tasks_with_open_root_task
    child_tasks.active.where.not(type: IGNORED_ACTIVE_TASKS) if @appeal.root_task&.open?
  end

  # Based on high-count, 100% frequency stats from:
  # https://department-of-veterans-affairs.github.io/caseflow/task_trees/trees/docket-DR/freq-parentchild.html
  # https://department-of-veterans-affairs.github.io/caseflow/task_trees/trees/docket-ES/freq-parentchild.html
  # https://department-of-veterans-affairs.github.io/caseflow/task_trees/trees/docket-H/freq-parentchild.html
  # rubocop:disable Metrics/AbcSize
  def expected_child_task_hash
    @expected_child_task_hash ||= {
      # org-task that expect an associated user-task
      InformalHearingPresentationTask.assigned_to_any_org => InformalHearingPresentationTask.assigned_to_any_user,
      SendCavcRemandProcessedLetterTask.assigned_to_any_org => SendCavcRemandProcessedLetterTask.assigned_to_any_user,
      EvidenceSubmissionWindowTask.assigned_to_any_org => EvidenceSubmissionWindowTask.assigned_to_any_user,
      TranslationTask.assigned_to_any_org => TranslationTask.assigned_to_any_user,
      QualityReviewTask.assigned_to_any_org => QualityReviewTask.assigned_to_any_user,
      BvaDispatchTask.assigned_to_any_org => BvaDispatchTask.assigned_to_any_user,
      FoiaTask.assigned_to_any_org => FoiaTask.assigned_to_any_user,

      # Colocated org-task that expect an associated Colocated user-task child
      IhpColocatedTask.assigned_to_any_org => IhpColocatedTask.assigned_to_any_user,
      ExtensionColocatedTask.assigned_to_any_org => ExtensionColocatedTask.assigned_to_any_user,
      MissingRecordsColocatedTask.assigned_to_any_org => MissingRecordsColocatedTask.assigned_to_any_user,
      PoaClarificationColocatedTask.assigned_to_any_org => PoaClarificationColocatedTask.assigned_to_any_user,
      OtherColocatedTask.assigned_to_any_org => OtherColocatedTask.assigned_to_any_user,

      # Mail org-task that expect an associated Mail user-task child
      DocketSwitchMailTask.assigned_to_any_org => DocketSwitchMailTask.assigned_to_any_user,

      # different task types
      FoiaColocatedTask.assigned_to_any_org => FoiaTask.assigned_to_any_org,
      QualityReviewTask.assigned_to_any_user => JudgeQualityReviewTask.assigned_to_any_user,
      BvaDispatchTask.assigned_to_any_user => JudgeDispatchReturnTask.assigned_to_any_user
    }
  end
  # rubocop:enable Metrics/AbcSize

  def unexpected_child_tasks
    expected_child_task_hash.map do |parent_task_query, child_task_query|
      parent_task_query.where(appeal: @appeal).map do |parent|
        parent.children - child_task_query.where(appeal: @appeal) - TimedHoldTask.where(appeal: @appeal)
      end.select(&:any?)
    end.select(&:any?).flatten
  end

  # Based on high-count, 100% frequency stats from:
  # https://department-of-veterans-affairs.github.io/caseflow/task_trees/trees/docket-DR/freq-childparent.html
  # https://department-of-veterans-affairs.github.io/caseflow/task_trees/trees/docket-ES/freq-childparent.html
  # https://department-of-veterans-affairs.github.io/caseflow/task_trees/trees/docket-H/freq-childparent.html
  # rubocop:disable Metrics/AbcSize
  def expected_parent_task_hash
    @expected_parent_task_hash ||= {
      # task types expected under RootTask
      DistributionTask.assigned_to_any_org => RootTask.assigned_to_any_org,
      TrackVeteranTask.assigned_to_any_org => RootTask.assigned_to_any_org,
      JudgeAssignTask.assigned_to_any_user => RootTask.assigned_to_any_org,
      JudgeDecisionReviewTask.assigned_to_any_user => RootTask.assigned_to_any_org,
      QualityReviewTask.assigned_to_any_org => RootTask.assigned_to_any_org,
      BvaDispatchTask.assigned_to_any_org => RootTask.assigned_to_any_org,
      VeteranRecordRequest.assigned_to_any_org => RootTask.assigned_to_any_org,

      # task types expected under DistributionTask
      EvidenceSubmissionWindowTask.assigned_to_any_org => DistributionTask.assigned_to_any_org,
      HearingTask.assigned_to_any_org => DistributionTask.assigned_to_any_org,
      SpecialCaseMovementTask.assigned_to_any_user => DistributionTask.assigned_to_any_org,
      CavcTask.assigned_to_any_org => DistributionTask.assigned_to_any_org,

      ScheduleHearingTask.assigned_to_any_org => HearingTask.assigned_to_any_org,
      AssignHearingDispositionTask.assigned_to_any_org => HearingTask.assigned_to_any_org,
      # Interesting that ChangeHearingDispositionTask user-task is never a child of its org-task:
      ChangeHearingDispositionTask.assigned_to_any_org => HearingTask.assigned_to_any_org,
      ChangeHearingDispositionTask.assigned_to_any_user => ScheduleHearingTask.assigned_to_any_org,
      HearingAdminActionVerifyAddressTask.assigned_to_any_org => ScheduleHearingTask.assigned_to_any_org,

      SendCavcRemandProcessedLetterTask.assigned_to_any_org => CavcTask.assigned_to_any_org,
      CavcRemandProcessedLetterResponseWindowTask.assigned_to_any_org => CavcTask.assigned_to_any_org,

      # different task types
      AttorneyTask.assigned_to_any_user => JudgeDecisionReviewTask.assigned_to_any_user,
      AttorneyRewriteTask.assigned_to_any_user => JudgeDecisionReviewTask.assigned_to_any_user,
      JudgeQualityReviewTask.assigned_to_any_user => QualityReviewTask.assigned_to_any_user,
      JudgeDispatchReturnTask.assigned_to_any_user => BvaDispatchTask.assigned_to_any_user,
      FoiaTask.assigned_to_any_org => FoiaColocatedTask.assigned_to_any_org,

      # user-task types that expect an associated org-task parent
      InformalHearingPresentationTask.assigned_to_any_user => InformalHearingPresentationTask.assigned_to_any_org,
      EvidenceSubmissionWindowTask.assigned_to_any_user => EvidenceSubmissionWindowTask.assigned_to_any_org,
      TranslationTask.assigned_to_any_user => TranslationTask.assigned_to_any_org,
      TranscriptionTask.assigned_to_any_user => TranscriptionTask.assigned_to_any_org,
      QualityReviewTask.assigned_to_any_user => QualityReviewTask.assigned_to_any_org,
      BvaDispatchTask.assigned_to_any_user => BvaDispatchTask.assigned_to_any_org,
      FoiaTask.assigned_to_any_user => FoiaTask.assigned_to_any_org,
      CavcRemandProcessedLetterResponseWindowTask.assigned_to_any_user =>
        CavcRemandProcessedLetterResponseWindowTask.assigned_to_any_org,

      # Colocated user-task that expect an associated Colocated org-task parent
      IhpColocatedTask.assigned_to_any_user => IhpColocatedTask.assigned_to_any_org,
      OtherColocatedTask.assigned_to_any_user => OtherColocatedTask.assigned_to_any_org,

      # Mail user-task that expect an associated Mail org-task parent
      AodMotionMailTask.assigned_to_any_user => AodMotionMailTask.assigned_to_any_org,
      EvidenceOrArgumentMailTask.assigned_to_any_user => EvidenceOrArgumentMailTask.assigned_to_any_org,
      StatusInquiryMailTask.assigned_to_any_user => StatusInquiryMailTask.assigned_to_any_org
    }
  end
  # rubocop:enable Metrics/AbcSize

  def tasks_with_unexpected_parent_task
    expected_parent_task_hash.map do |child_task_query, parent_task_query|
      child_task_query.where(appeal: @appeal).reject do |child|
        parent_task_query.where(appeal: @appeal).include?(child.parent)
      end
    end.select(&:any?).flatten
  end

  # See AppealsWithNoTasksOrAllTasksOnHoldQuery#dispatched_appeals_on_hold
  def open_root_task_for_dispatched_appeal?
    dispatched = @appeal.tasks.assigned_to_any_org.find_by_type(:BvaDispatchTask)&.completed?
    @appeal.root_task&.open? && @appeal.decision_document && dispatched
  end

  # See AppealsWithMoreThanOneOpenHearingTaskChecker
  def extra_open_hearing_tasks
    hearing_tasks = @appeal.tasks.open.of_type(:HearingTask)
    hearing_tasks.drop 1
  end

  # Task types where only one of each type should be open at a time.
  # Some of these have Rails validations to prevent more than 1 open of the task type
  # but the validations can be subverted, so let's check them here just in case.
  # https://department-of-veterans-affairs.github.io/caseflow/task_trees/trees/tasks-overview.html
  # Example: https://github.com/department-of-veterans-affairs/dsva-vacols/issues/217#issuecomment-906779760
  SINGULAR_OPEN_TASKS ||= %w[RootTask DistributionTask
                             HearingTask ScheduleHearingTask AssignHearingDispositionTask ChangeHearingDispositionTask
                             JudgeAssignTask JudgeDecisionReviewTask
                             AttorneyTask AttorneyRewriteTask
                             JudgeQualityReviewTask AttorneyQualityReviewTask
                             JudgeDispatchReturnTask AttorneyDispatchReturnTask
                             VeteranRecordRequest].freeze
  SINGULAR_OPEN_ORG_TASKS ||= %w[QualityReviewTask BvaDispatchTask].freeze

  def extra_open_tasks
    @appeal.tasks.select(:type).open.of_type(SINGULAR_OPEN_TASKS).group(:type).having("count(*) > 1").count
  end

  def extra_open_org_tasks
    @appeal.tasks.select(:type).open.assigned_to_any_org.of_type(SINGULAR_OPEN_ORG_TASKS)
      .group(:type).having("count(*) > 1").count
  end

  def open_exclusive_root_children_tasks
    MultipleOpenRootChildTaskChecker.open_exclusive_root_children_tasks(@appeal)
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

  def child_tasks
    @appeal.tasks.where.not(parent_id: nil)
  end
end
