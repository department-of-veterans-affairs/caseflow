# frozen_string_literal: true

##
# Task tracking work done by attorneys at BVA. Attorneys are assigned tasks by judges.
# Attorney tasks include:
#   - writing draft decisions for judges
#   - adding admin actions (like translating documents)

class AttorneyTask < Task
  validates :assigned_by, presence: true
  validates :parent, presence: true, if: :ama?

  validate :assigned_by_role_is_valid
  validate :assigned_to_role_is_valid
  validate :child_attorney_tasks_are_completed, on: :create

  after_update :send_back_to_judge_assign, if: :attorney_task_just_cancelled?

  def available_actions(user)
    # Both the judge who assigned this task and the judge who is assigned the parent review task get these actions
    if parent.is_a?(JudgeTask) && (parent.assigned_to == user || assigned_by == user)
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end

    return [] if assigned_to != user

    [
      (Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h if ama? && appeal.vacate?),
      Constants.TASK_ACTIONS.REVIEW_DECISION_DRAFT.to_h,
      Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
      Constants.TASK_ACTIONS.CANCEL_TASK.to_h
    ].compact
  end

  def timeline_title
    COPY::CASE_TIMELINE_ATTORNEY_TASK
  end

  def update_parent_status
    parent.begin_decision_review_phase if parent&.is_a?(JudgeAssignTask)
    super
  end

  def self.label
    COPY::ATTORNEY_TASK_LABEL
  end

  def stays_with_reassigned_parent?
    super || completed?
  end

  private

  def child_attorney_tasks_are_completed
    if parent&.children_attorney_tasks&.open&.any?
      errors.add(:parent, "has open child tasks")
    end
  end

  def assigned_to_role_is_valid
    errors.add(:assigned_to, "has to be an attorney") if assigned_to && !assigned_to.attorney_in_vacols?
  end

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be a judge") if assigned_by && !assigned_by.judge_in_vacols?
  end

  def attorney_task_just_cancelled?
    type.eql?(AttorneyTask.name) && saved_change_to_attribute?("status") && cancelled?
  end

  def send_back_to_judge_assign
    transaction do
      cancel_parent_judge_review
      open_judge_assign_task
    end
  end

  def cancel_parent_judge_review
    parent.update!(status: Constants.TASK_STATUSES.cancelled)
  end

  def open_judge_assign_task
    JudgeAssignTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: assigned_by)
  end
end
