# frozen_string_literal: true

##
# Task tracking work done by attorneys at BVA. Attorneys are assigned tasks by judges.
# Attorney tasks include:
#   - writing draft decisions for judges
#   - adding admin actions (like translating documents)
# While these are normally assigned to an attorney of the judge, it is possible for
# them to be assigned to an attorney from another team or even the assigning VLJ themselves

class AttorneyTask < Task
  validate :only_open_task_of_type, on: :create,
                                    unless: :skip_check_for_only_open_task_of_type

  validates :assigned_by, presence: true
  validates :parent, presence: true, if: :ama?

  validate :assigned_by_role_is_valid, if: :will_save_change_to_assigned_by_id?
  validate :assigned_to_role_is_valid, if: :will_save_change_to_assigned_to_id?

  def available_actions(user)
    atty_actions = [
      (Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h if ama? && appeal.vacate?),
      Constants.TASK_ACTIONS.REVIEW_DECISION_DRAFT.to_h,
      Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
      Constants.TASK_ACTIONS.CANCEL_AND_RETURN_TASK.to_h
    ].compact

    movement_actions = if appeal.is_a?(LegacyAppeal) && FeatureToggle.enable!(:vlj_legacy_appeal)
                         [
                           Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY_LEGACY.to_h,
                           Constants.TASK_ACTIONS.REASSIGN_TO_LEGACY_JUDGE.to_h
                         ]
                       else
                         [
                           Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h,
                           Constants.TASK_ACTIONS.CANCEL_AND_RETURN_TASK.to_h
                         ]
                       end

    actions_based_on_assignment(user, atty_actions, movement_actions)
  end

  def actions_based_on_assignment(user, atty_actions, movement_actions)
    if self_assigned?(user)
      # VLJ w/ self-assigned task can do most things (return to judge doesn't make sense)
      (atty_actions + [Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h]).uniq
    elsif can_be_moved_by_user?(user) && !self_assigned?(user)
      movement_actions
    else
      return [] if assigned_to != user

      atty_actions
    end
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
    FeatureToggle.enabled?(:overtime_persistence, user: RequestStore[:current_user]) ? false : true
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

    # Allows SSC, SCM, VLJ's if legacy
    if appeal.is_a?(LegacyAppeal)
      return parent.assigned_to == user || assigned_by == user || user&.can_act_on_behalf_of_legacy_judges?
    end

    # The judge who is assigned the parent review task, the assigning judge, and SpecialCaseMovementTeam members can
    # cancel or reassign this task
    parent.assigned_to == user || assigned_by == user || user&.can_act_on_behalf_of_judges?
  end

  # VLJs can assign these to themselves
  def self_assigned?(user)
    return false unless parent.is_a?(JudgeTask)

    assigned_to == user && assigned_by == user
  end

  def assigned_to_role_is_valid
    is_self = assigned_to == assigned_by

    errors.add(:assigned_to, "has to be an attorney") if assigned_to && !assigned_to.attorney_in_vacols? && !is_self
  end

  def assigned_by_role_is_valid
    if assigned_by && (!assigned_by.judge? && !assigned_by.can_act_on_behalf_of_judges? &&
      !assigned_by.can_act_on_behalf_of_legacy_judges?)
      errors.add(:assigned_by, "has to be a judge or special case movement team member")
    end
  end

  def open_judge_assign_task
    JudgeAssignTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: parent.assigned_to)
  end
end
