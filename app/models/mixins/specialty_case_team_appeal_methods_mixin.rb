# frozen_string_literal: true

module SpecialtyCaseTeamMethods
  def sct_appeal?
    request_issues.active.any?(&:sct_benefit_type?)
  end

  def distributed?
    tasks.any? { |task| task.is_a?(SpecialtyCaseTeamAssignTask) }
  end

  def specialty_case_team_assign_task?
    tasks.any? { |task| task.is_a?(SpecialtyCaseTeamAssignTask) }
  end

  def remove_from_current_queue!
    tasks.reject { |task| %w[RootTask DistributionTask].include?(task.type) }
      .each(&:cancel_task_and_child_subtasks)
  end

  def reopen_distribution_task!(user)
    distribution_task = tasks.find { |task| task.type == DistributionTask.name }
    distribution_task.update!(status: "assigned", assigned_to: Bva.singleton, assigned_by: user)
  end

  # :reek:FeatureEnvy
  def completed_specialty_case_team_assign_task?
    tasks.completed?.any? { |task| task.is_a?(SpecialtyCaseTeamAssignTask) && task.completed? }
  end

  def remove_from_specialty_case_team!
    tasks.find { |task| task.is_a?(SpecialtyCaseTeamAssignTask) }.cancelled!
  end
end
