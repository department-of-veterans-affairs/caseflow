# frozen_string_literal: true

# The SpecialtyCaseTeamSplitAppealHandler handles cancelling, moving, and creating tasks after splitting an appeal
# That contains Specialty Case Team issues
class SpecialtyCaseTeamSplitAppealHandler
  attr_reader :old_appeal
  attr_reader :new_appeal

  def initialize(old_appeal, new_appeal)
    # super
    @old_appeal = old_appeal
    @new_appeal = new_appeal
  end

  def handle_split_sct_appeals
    return unless old_appeal.has_distribution_task?

    old_sct_appeal = old_appeal.sct_appeal?
    new_sct_appeal = new_appeal.sct_appeal?
    both_sct_appeals = old_sct_appeal && new_sct_appeal

    if both_sct_appeals
      # We only need something here if we are cancelling the judge/attorney tasks. Otherwise a standard clone works
      # assign_appeal_to_the_specialty_case_team(new_appeal)
    elsif old_sct_appeal
      handle_old_sct_appeal
    elsif new_sct_appeal
      handle_new_sct_appeal
    end
  end

  private

  def handle_old_sct_appeal
    # If the old appeal was not in the sct queue, then it needs to be moved there and it was an old appeal before SCT
    move_appeal_back_to_distribution(new_appeal)
    unless was_already_in_sct_queue?
      assign_appeal_to_the_specialty_case_team(old_appeal)
    end
  end

  def handle_new_sct_appeal
    # If the old appeal was not in the sct queue, then it needs to be moved there and it was an old appeal before SCT
    move_appeal_back_to_distribution(old_appeal)
    unless was_already_in_sct_queue?
      assign_appeal_to_the_specialty_case_team(new_appeal)
    end
  end

  def was_already_in_sct_queue?
    old_appeal.tasks.any? { |task| task.type == SpecialtyCaseTeamAssignTask.name }
  end

  def move_appeal_back_to_distribution(appeal)
    # Reopen the Distribution task
    distribution_task = appeal.tasks.find { |task| task.type == DistributionTask.name }
    distribution_task.update!(status: "assigned", assigned_to: Bva.singleton, assigned_by: current_user)

    # Cancel any open Judge, Attorney, or SpecialtyCaseTeam tasks
    cancelled_task_types = %w[SpecialtyCaseTeamAssignTask JudgeDecisionReviewTask JudgeAssignTask AttorneyTask]
    appeal.tasks.select { |task| cancelled_task_types.include?(task.type) }.each(&:cancel_task_and_child_subtasks)
    appeal.reload
    appeal
  end

  # TODO: This should be the same as Jonathan's method. Use the same way in both places
  def assign_appeal_to_the_specialty_case_team(appeal)
    remove_appeal_from_current_queue(appeal)
    SpecialtyCaseTeamAssignTask.find_or_create_by(
      appeal: appeal,
      parent: appeal.root_task,
      assigned_to: SpecialtyCaseTeam.singleton,
      assigned_by: current_user,
      status: Constants.TASK_STATUSES.assigned
    )
    appeal.reload
    appeal
  end

  # TODO: This should definitely be moved to the appeal model
  # TODO: Verify that this does not do bad things like cancelling tasks that are not supposed to be cancelled
  # Like open Hearing tasks or open mail tasks that might not be dependent on what queue the appeal is in
  def remove_appeal_from_current_queue(appeal)
    appeal.tasks.reject { |task| %w[RootTask DistributionTask].include?(task.type) }
      .each(&:cancel_task_and_child_subtasks)
  end
end
