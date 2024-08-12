# frozen_string_literal: true

module SpecialtyCaseTeamMethodsMixin
  def sct_appeal?
    request_issues.active.any?(&:sct_benefit_type?)
  end

  # :reek:FeatureEnvy
  def distributed?
    tasks.any? { |task| task.is_a?(DistributionTask) && task.completed? }
  end

  def distribution_task?
    tasks.any? { |task| task.is_a?(DistributionTask) }
  end

  def specialty_case_team_assign_task?
    tasks.any? { |task| task.is_a?(SpecialtyCaseTeamAssignTask) }
  end

  def remove_from_current_queue!
    tasks.reject { |task| %w[RootTask DistributionTask].include?(task.type) }
      .each(&:cancel_task_and_child_subtasks)
  end

  def reopen_distribution_task!(user)
    distribution_task = tasks.find { |task| task.is_a?(DistributionTask) }
    distribution_task.update!(status: Constants.TASK_STATUSES.assigned, assigned_to: Bva.singleton, assigned_by: user)
  end

  # :reek:FeatureEnvy
  def completed_specialty_case_team_assign_task?
    tasks.any? { |task| task.is_a?(SpecialtyCaseTeamAssignTask) && task.completed? }
  end

  def remove_from_specialty_case_team!
    tasks.find { |task| task.is_a?(SpecialtyCaseTeamAssignTask) }&.cancelled!
  end

  def move_appeal_back_to_distribution!(user)
    reopen_distribution_task!(user)
    remove_from_current_queue!
    remove_from_specialty_case_team!
  end
end
