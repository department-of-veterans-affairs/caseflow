# frozen_string_literal: true

# The SpecialtyCaseTeamSplitAppealHandler handles cancelling, moving, and creating tasks after splitting an appeal
# That contains Specialty Case Team issues
class SpecialtyCaseTeamSplitAppealHandler
  attr_reader :old_appeal
  attr_reader :new_appeal
  attr_reader :current_user

  def initialize(old_appeal, new_appeal, current_user)
    @old_appeal = old_appeal
    @new_appeal = new_appeal
    @current_user = current_user
  end

  def handle_split_sct_appeals
    return unless old_appeal.distributed?

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
    # If the old appeal was not in the sct queue, then the new appeal needs to be moved there
    # The appeal was created before the SpecialtyCaseTeam was created or before the issue type was added to SCT.
    new_appeal.move_appeal_back_to_distribution!(current_user)
    unless old_appeal.specialty_case_team_assign_task?
      assign_appeal_to_the_specialty_case_team(old_appeal)
    end
  end

  def handle_new_sct_appeal
    # If the old appeal was not in the sct queue, then the old appeal needs to be moved there
    # The appeal was created before the SpecialtyCaseTeam was created or before the issue type was added to SCT.
    old_appeal.move_appeal_back_to_distribution!(current_user)
    unless old_appeal.specialty_case_team_assign_task?
      assign_appeal_to_the_specialty_case_team(new_appeal)
    end
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
end
