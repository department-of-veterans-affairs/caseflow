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

  def actions_available?(user)
    SpecialCaseMovementTeam.singleton.user_has_access?(user)
  end

  def available_actions(user)
    return [] unless user

    if SpecialCaseMovementTeam.singleton.user_has_access?(user)
      return [Constants.TASK_ACTIONS.SPECIAL_CASE_MOVEMENT.to_h] if appeal.ready_for_distribution?

      if FeatureToggle.enabled?(:scm_move_with_blocking_tasks, user: user) && !appeal.ready_for_distribution?
        return [Constants.TASK_ACTIONS.BLOCKED_SPECIAL_CASE_MOVEMENT.to_h]
      end
    end

    []
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
end
