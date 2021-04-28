# frozen_string_literal: true

# Determine the BVA workflow status of an Appeal (symbol and string) based on its Tasks.

class BVAAppealStatus
  attr_reader :status

  SORT_KEYS = {
    not_distributed: 1,
    distributed_to_judge: 2,
    assigned_to_attorney: 3,
    assigned_to_colocated: 4,
    in_progress: 5,
    ready_for_signature: 6,
    signed: 7,
    dispatched: 8,
    on_hold: 9,
    cancelled: 10,
    misc: 11,
    unknown: 12,
    post_dispatch: 13,
    docket_switched: 14
  }.freeze

  DEFINITIONS = {
    not_distributed: "1. Not distributed",
    distributed_to_judge: "2. Distributed to judge",
    assigned_to_attorney: "3. Assigned to attorney",
    assigned_to_colocated: "4. Assigned to colocated",
    in_progress: "5. Decision in progress",
    ready_for_signature: "6. Decision ready for signature",
    signed: "7. Decision signed",
    dispatched: "8. Decision dispatched",
    cancelled: "CANCELLED",
    misc: "MISC",
    on_hold: "ON HOLD",
    unknown: "UNKNOWN",
    post_dispatch: "9. Post dispatch tasks",
    docket_switched: "10. Docket Switch (Inactive)"
  }.freeze

  MISC_TASK_NAMES = %w[
    JudgeQualityReviewTask
    JudgeDispatchReturnTask
    AttorneyQualityReviewTask
    AttorneyDispatchReturnTask
  ].freeze

  ATTORNEY_TASK_NAMES = %w[
    AttorneyTask
    AttorneyRewriteTask
  ].freeze

  class << self
    def colocated_task_names
      @colocated_task_names ||= ColocatedTask.subclasses.map(&:name)
    end

    def misc_task_names
      MISC_TASK_NAMES
    end

    def attorney_task_names
      ATTORNEY_TASK_NAMES
    end
  end

  def initialize(appeal:)
    @appeal = appeal
    @status = compute
  end

  def to_sym
    status
  end

  def to_s
    DEFINITIONS[status]
  end

  def to_i
    SORT_KEYS[status]
  end

  def as_json(_args)
    to_sym
  end

  private

  attr_reader :appeal

  delegate :tasks, to: :appeal

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def compute
    if open_distribution_task? && !open_timed_hold_task?
      :not_distributed
    elsif active_judge_assign_task?
      :distributed_to_judge
    elsif assigned_attorney_task?
      :assigned_to_attorney
    elsif active_colocated_task?
      :assigned_to_colocated
    elsif attorney_task_in_progress?
      :in_progress
    elsif active_judge_decision_review_task?
      :ready_for_signature
    elsif active_sign_task?
      :signed
    elsif completed_dispatch_task? && open_tasks.empty?
      :dispatched
    elsif completed_dispatch_task?
      :post_dispatch
    elsif docket_switched?
      :docket_switched
    elsif cancelled_root_task?
      :cancelled
    elsif misc_task?
      :misc
    elsif open_timed_hold_task?
      :on_hold
    else
      :unknown
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def open_tasks
    @open_tasks ||= tasks.open
  end

  def active_tasks
    @active_tasks ||= tasks.active
  end

  def assigned_tasks
    @assigned_tasks ||= tasks.assigned
  end

  def in_progress_tasks
    @in_progress_tasks ||= tasks.in_progress
  end

  def cancelled_tasks
    @cancelled_tasks ||= tasks.cancelled
  end

  def completed_tasks
    @completed_tasks ||= tasks.completed
  end

  def open_distribution_task?
    open_tasks.any? { |task| task.is_a?(DistributionTask) }
  end

  def open_timed_hold_task?
    open_tasks.any? { |task| task.is_a?(TimedHoldTask) }
  end

  def active_judge_assign_task?
    active_tasks.any? { |task| task.is_a?(JudgeAssignTask) }
  end

  def assigned_attorney_task?
    assigned_tasks.any? { |task| self.class.attorney_task_names.include?(task.type) }
  end

  def active_colocated_task?
    active_tasks.any? { |task| self.class.colocated_task_names.include?(task.type) }
  end

  def attorney_task_in_progress?
    in_progress_tasks.any? { |task| self.class.attorney_task_names.include?(task.type) }
  end

  def active_judge_decision_review_task?
    active_tasks.any? { |task| task.is_a?(JudgeDecisionReviewTask) }
  end

  def active_sign_task?
    active_tasks.any? { |task| %w[BvaDispatchTask QualityReviewTask].include?(task.type) }
  end

  def completed_dispatch_task?
    completed_tasks.any? { |task| task.is_a?(BvaDispatchTask) }
  end

  def docket_switched?
    # TODO: this should be updated to check that there are no active tasks once the task handling is implemented
    completed_tasks.any? { |task| task.is_a?(DocketSwitchGrantedTask) }
  end

  def cancelled_root_task?
    cancelled_tasks.any? { |task| task.is_a?(RootTask) }
  end

  def misc_task?
    active_tasks.any? { |task| self.class.misc_task_names.include?(task.type) }
  end
end
