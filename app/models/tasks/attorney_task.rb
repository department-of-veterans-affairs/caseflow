class AttorneyTask < Task
  validates :assigned_by, presence: true
  validates :parent, presence: true, if: :ama?

  validate :assigned_by_role_is_valid
  validate :assigned_to_role_is_valid
  validate :child_attorney_tasks_are_completed, on: :create

  def available_actions(user)
    if parent.is_a?(JudgeTask) && parent.assigned_to == user
      return [Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h]
    end

    return [] if assigned_to != user

    [Constants.TASK_ACTIONS.REVIEW_DECISION.to_h, Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h]
  end

  def timeline_title
    COPY::CASE_TIMELINE_ATTORNEY_TASK
  end

  private

  def child_attorney_tasks_are_completed
    if parent&.children_attorney_tasks&.any? { |task| task.status != Constants.TASK_STATUSES.completed }
      errors.add(:parent, "has open child tasks")
    end
  end

  def assigned_to_role_is_valid
    errors.add(:assigned_to, "has to be an attorney") if assigned_to && !assigned_to.attorney_in_vacols?
  end

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be a judge") if assigned_by && !assigned_by.judge_in_vacols?
  end
end
