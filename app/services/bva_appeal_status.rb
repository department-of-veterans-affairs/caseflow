# frozen_string_literal: true

# Determine the BVA workflow status of an Appeal (symbol and string) based on its Tasks.

class BVAAppealStatus
  attr_reader :status, :tasks

  SORT_KEYS = {
    not_distributed: 1,
    distributed_to_judge: 2,
    distributed_to_specialty_case_team: 2,
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
    docket_switched: 14,
    pre_docketed: 15
  }.freeze

  DEFINITIONS = {
    not_distributed: "1. Not distributed",
    distributed_to_judge: "2. Distributed to judge",
    distributed_to_specialty_case_team: "2. Distributed to SCT",
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
    docket_switched: "10. Docket Switch (Inactive)",
    pre_docketed: "Pre-docketed"
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

  Tasks = Struct.new(
    :open,
    :active,
    :in_progress,
    :cancelled,
    :completed,
    :assigned,
    keyword_init: true
  )

  def initialize(tasks:)
    @tasks = tasks
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

  def as_json(_args = nil)
    to_sym
  end

  private

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
  def compute
    if open_pre_docket_task?
      :pre_docketed
    elsif open_distribution_task? && !open_timed_hold_task?
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
    elsif completed_dispatch_task? && tasks.open.empty?
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
    elsif active_specialty_case_team_assign_task?
      :distributed_to_specialty_case_team
    else
      :unknown
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength

  def open_pre_docket_task?
    tasks.open.any? { |task| task.type == "PreDocketTask" }
  end

  def open_distribution_task?
    tasks.open.any? { |task| task.type == "DistributionTask" }
  end

  def open_timed_hold_task?
    tasks.open.any? { |task| task.type == "TimedHoldTask" }
  end

  def active_judge_assign_task?
    tasks.active.any? { |task| task.type == "JudgeAssignTask" }
  end

  def assigned_attorney_task?
    tasks.assigned.any? { |task| self.class.attorney_task_names.include?(task.type) }
  end

  def active_colocated_task?
    tasks.active.any? { |task| self.class.colocated_task_names.include?(task.type) }
  end

  def attorney_task_in_progress?
    tasks.in_progress.any? { |task| self.class.attorney_task_names.include?(task.type) }
  end

  def active_judge_decision_review_task?
    tasks.active.any? { |task| task.type == "JudgeDecisionReviewTask" }
  end

  def active_sign_task?
    tasks.active.any? { |task| %w[BvaDispatchTask QualityReviewTask].include?(task.type) }
  end

  def completed_dispatch_task?
    tasks.completed.any? { |task| task.type == "BvaDispatchTask" }
  end

  def docket_switched?
    # TODO: this should be updated to check that there are no active tasks once the task handling is implemented
    tasks.completed.any? { |task| task.type == "DocketSwitchGrantedTask" }
  end

  def cancelled_root_task?
    tasks.cancelled.any? { |task| task.type == "RootTask" }
  end

  def misc_task?
    tasks.active.any? { |task| self.class.misc_task_names.include?(task.type) }
  end

  def active_specialty_case_team_assign_task?
    tasks.active.any? { |task| task.type == "SpecialtyCaseTeamAssignTask" }
  end
end
