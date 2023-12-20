# frozen_string_literal: true

##
# This task is used to either confirm that a hearing has been scheduled
# or create a ScheduleHearingTask indicating that a hearing needs to be scheduled.

class ScheduleHearingColocatedTask < ColocatedTask
  after_update :send_to_hearings_branch, if: :just_completed_ama_organization_task?

  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.schedule_hearing
  end

  def self.default_assignee
    HearingsManagement.singleton
  end

  def available_actions(user)
    if task_is_assigned_to_users_organization?(user) || assigned_to.eql?(user)
      return [
        Constants.TASK_ACTIONS.SCHEDULE_HEARING_SEND_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end

    if task_is_assigned_to_user_within_admined_hearing_organization?(user)
      return [Constants.TASK_ACTIONS.REASSIGN_TO_HEARINGS_TEAMS_MEMBER.to_h]
    end

    []
  end

  private

  def vacols_location
    # Return to attorney if the task is cancelled. For instance, if HearingsManagement sees that the hearing was
    # actually held.
    if (children.present? && children.all? { |child| child.status == Constants.TASK_STATUSES.cancelled }) ||
       status == Constants.TASK_STATUSES.cancelled
      return assigned_by.vacols_uniq_id
    end

    LegacyAppeal::LOCATION_CODES[:schedule_hearing]
  end

  def just_completed_ama_organization_task?
    appeal_type.eql?(Appeal.name) &&
      saved_change_to_status? &&
      completed? &&
      assigned_to.is_a?(Organization)
  end

  def send_to_hearings_branch
    parent = DistributionTask.create!(appeal: appeal, parent: appeal.root_task)
    ScheduleHearingTask.create!(appeal: appeal, parent: parent)
    JudgeTask.open.where(appeal: appeal).find_each(&:cancel_task_and_child_subtasks)
    DistributedCase.find_by(case_id: appeal.uuid)&.rename_for_redistribution!
  end
end
