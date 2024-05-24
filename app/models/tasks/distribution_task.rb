# frozen_string_literal: true

##
# A DistributionTask is created after the intake process is completed on an AMA case.
# This task signals that an appeal is ready for distribution to a judge, including for auto case distribution.
#   - When the distribution task is assigned, Automatic Case Distribution can distribute the case to a judge.
#     This completes the DistributionTask and creates a JudgeAssignTask, assigned to the judge.
#
# Expected parent task: RootTask
#
# Child tasks under the DistributionTask places it on hold and blocks the selection for distribution to a judge.
# A child task is autocreated for certain dockets -- see `InitialTasksFactory.create_subtasks!`

class DistributionTask < Task
  before_validation :set_assignee

  after_update :update_affinity_start_date, if: :assigned_affinity_start_date?

  def actions_available?(user)
    SpecialCaseMovementTeam.singleton.user_has_access?(user)
  end

  def available_actions(user)
    return [] unless user

    if special_case_movement_task(user)
      return [Constants.TASK_ACTIONS.SPECIAL_CASE_MOVEMENT.to_h]
    elsif SpecialCaseMovementTeam.singleton.user_has_access?(user) && blocked_special_case_movement(user)
      return [Constants.TASK_ACTIONS.BLOCKED_SPECIAL_CASE_MOVEMENT.to_h]
    elsif FeatureToggle.enabled?(:docket_switch, user: user)
      return [Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h]
    end

    []
  end

  def special_case_movement_task(user)
    SpecialCaseMovementTeam.singleton.user_has_access?(user) && appeal.ready_for_distribution?
  end

  def blocked_special_case_movement(user)
    FeatureToggle.enabled?(:scm_move_with_blocking_tasks, user: user) && !appeal.ready_for_distribution?
  end

  def ready_for_distribution!
    update!(status: :assigned, assigned_at: Time.zone.now)
  end

  def ready_for_distribution_at
    assigned_at
  end

  def visible_blocking_tasks
    visible_descendants = descendants.reject(&:hide_from_case_timeline).select(&:open?)

    visible_descendants - [self]
  end

  private

  def set_assignee
    self.assigned_to ||= Bva.singleton
  end

  def update_affinity_start_date
    # update affinity start date with instructions
    appeal.appeal_affinity.update!(affinity_start_date: nil)
    instructions.push("Appeal affinity start date value was removed.")
    save!
  end

  def assigned_affinity_start_date?
    saved_change_to_attribute?("status") && status == "assigned" && appeal.appeal_affinity&.affinity_start_date
  end
end
