# frozen_string_literal: true

##
# Task tracking work done by attorneys at BVA. Attorneys are assigned tasks by judges.
# Attorney tasks include:
#   - writing draft decisions for judges
#   - adding admin actions (like translating documents)

class AttorneyTask < Task
  validates :assigned_by, presence: true
  validates :parent, presence: true, if: :ama?

  validate :assigned_by_role_is_valid, if: :will_save_change_to_assigned_by_id?
  validate :assigned_to_role_is_valid, if: :will_save_change_to_assigned_to_id?

  def available_actions(user)
    if can_be_moved_by_user?(user)
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h,
        Constants.TASK_ACTIONS.CANCEL_AND_RETURN_TASK.to_h
      ]
    end

    return [] if assigned_to != user

    [
      (Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h if ama? && appeal.vacate?),
      Constants.TASK_ACTIONS.REVIEW_DECISION_DRAFT.to_h,
      Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
      Constants.TASK_ACTIONS.CANCEL_AND_RETURN_TASK.to_h
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

  def reassign_clears_overtime?
    true
  end

  def send_back_to_judge_assign!(params = {})
    transaction do
      update_with_instructions(params.merge(status: :cancelled))
      parent.update_with_instructions(params.merge(status: :cancelled))
      judge_assign_task = open_judge_assign_task

      [self, parent, judge_assign_task]
    end
  end

  def update_from_params(params, user)
    update_params_will_cancel_attorney_task?(params) ? send_back_to_judge_assign!(params) : super(params, user)
  end

  private

  def update_params_will_cancel_attorney_task?(params)
    type == AttorneyTask.name && params[:status].eql?(Constants.TASK_STATUSES.cancelled)
  end

  def can_be_moved_by_user?(user)
    return false unless parent.is_a?(JudgeTask)

    # The judge who is assigned the parent review task, the assigning judge, and SpecialCaseMovementTeam members can
    # cancel or reassign this task
    parent.assigned_to == user || assigned_by == user || user&.can_act_on_behalf_of_judges?
  end

  def assigned_to_role_is_valid
    errors.add(:assigned_to, "has to be an attorney") if assigned_to && !assigned_to.attorney_in_vacols?
  end

  def assigned_by_role_is_valid
    if assigned_by && (!assigned_by.judge? && !assigned_by.can_act_on_behalf_of_judges?)
      errors.add(:assigned_by, "has to be a judge or special case movement team member")
    end
  end

  def open_judge_assign_task
    JudgeAssignTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: parent.assigned_to)
  end
end
