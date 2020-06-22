# frozen_string_literal: true

class ScheduleHearingColocatedTask < ColocatedTask
  after_update :send_to_hearings_branch, if: :just_completed?

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

  def just_completed?
    appeal_type.eql?(Appeal.name) &&
      saved_change_to_status? &&
      completed? &&
      all_tasks_closed_for_appeal? &&
      assigned_to.is_a?(Organization)
  end

  def send_to_hearings_branch
    parent = DistributionTask.create!(appeal: appeal, parent: appeal.root_task)
    ScheduleHearingTask.create!(appeal: appeal, parent: parent)
    JudgeTask.open.where(appeal: appeal).find_each(&:cancel_task_and_child_subtasks)
    DistributedCase.find_by(case_id: appeal.uuid).update!(case_id: "#{appeal.uuid}-attempt1")
  end
end
