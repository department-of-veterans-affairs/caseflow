# frozen_string_literal: true

##
# Task that signals that an appeal is ready for distribution to a judge, including for auto case distribution.

class DistributionTask < GenericTask
  before_validation :set_assignee

  def available_actions(user)
    return [] unless user

    if special_case_movement_available?
      return [
        Constants.TASK_ACTIONS.SPECIAL_CASE_MOVEMENT.to_h
      ]
    end

    []
  end

  def ready_for_distribution!
    update!(status: :assigned, assigned_at: Time.zone.now)
  end

  def ready_for_distribution?
    assigned?
  end

  def ready_for_distribution_at
    assigned_at
  end

  private

  def special_case_movement_available?
    ::SpecialCaseMovementTeam.singleton.user_has_access?(user) &&
      appeal.ready_for_distribution?
  end

  def set_assignee
    self.assigned_to ||= Bva.singleton
  end
end
