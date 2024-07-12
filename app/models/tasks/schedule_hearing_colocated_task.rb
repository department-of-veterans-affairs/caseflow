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

  # Selects all judge tasks that are NOT QualityReviewJudgeTasks
  def handle_judge_tasks!
    judge_tasks = JudgeTask.open.where(appeal: appeal)
    non_quality_review_judge_tasks = judge_tasks.to_a.reject { |task| task.type == "JudgeQualityReviewTask" }
    # Converts array to active record association and runs cancel_task_and_child_subtasks
    JudgeTask.where(id: non_quality_review_judge_tasks.map(&:id)).find_each(&:cancel_task_and_child_subtasks)
  end

  def send_to_hearings_branch
    parent = DistributionTask.create!(appeal: appeal, parent: appeal.root_task)
    ScheduleHearingTask.create!(appeal: appeal, parent: parent)
    handle_judge_tasks!
    DistributedCase.find_by(case_id: appeal.uuid)&.rename_for_redistribution!
  end
end
