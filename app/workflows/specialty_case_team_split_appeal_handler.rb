# frozen_string_literal: true

# The SpecialtyCaseTeamSplitAppealHandler handles cancelling, moving, and creating tasks after splitting an appeal
# That contains Specialty Case Team issues
class SpecialtyCaseTeamSplitAppealHandler
  attr_reader :old_appeal
  attr_reader :new_appeal

  def initialize(old_appeal, new_appeal)
    @old_appeal = old_appeal
    @new_appeal = new_appeal
  end

  def handle_split_sct_appeals
    return unless old_appeal.has_distribution_task?

    old_sct_appeal = old_appeal.sct_appeal?
    new_sct_appeal = new_appeal.sct_appeal?
    both_sct_appeals = old_sct_appeal && new_sct_appeal

    if both_sct_appeals
      # We only need something here if we are cancelling the judge/attorney tasks. Otherwise a standard split works
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
    reopen_distribution_task(appeal)
    appeal.remove_from_current_queue!
  end

  def assign_appeal_to_the_specialty_case_team(appeal)
    appeal.remove_from_current_queue!
    create_new_specialty_case_team_assign_task(appeal)
  end

  def create_new_specialty_case_team_assign_task(appeal)
    sct_task = SpecialtyCaseTeamAssignTask.find_or_create_by(
      appeal: appeal,
      parent: appeal.root_task,
      assigned_to: SpecialtyCaseTeam.singleton
    )
    sct_task.update!(assigned_by: current_user, status: Constants.TASK_STATUSES.assigned)
  end

  def reopen_distribution_task(appeal)
    distribution_task = appeal.tasks.find { |task| task.type == DistributionTask.name }
    distribution_task.update!(status: "assigned", assigned_to: Bva.singleton, assigned_by: current_user)
  end
end
