# frozen_string_literal: true

##
# Model for tasks in generic organizational task queues. Supports common actions like:
#   - marking tasks complete
#   - assigning a task to a team
#   - assigning a task to an individual

class GenericTask < Task
  before_create :verify_org_task_unique

  # Use the existence of an organization-level task to prevent duplicates since there should only ever be one org-level
  # task active at a time for a single appeal.
  def verify_org_task_unique
    return if !active?

    if appeal.tasks.active.where(type: type, assigned_to: assigned_to).any? && assigned_to.is_a?(Organization)
      fail(
        Caseflow::Error::DuplicateOrgTask,
        appeal_id: appeal.id,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name
      )
    end
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def available_actions(user)
    return [] unless user

    if assigned_to == user
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
        Constants.TASK_ACTIONS.PLACE_HOLD.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end

    if task_is_assigned_to_user_within_organization?(user)
      return [
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h
      ]
    end

    if task_is_assigned_to_users_organization?(user)
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end

    []
  end

  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def placed_on_hold_at
    timed_hold_task&.created_at
  end

  # if we decide to remove the "on_hold_duration" column,
  # this method could just subtract the task timer expiration time from
  # # the hold task's created at.
  def on_hold_duration_days
    timed_hold_task&.on_hold_duration
  end

  def timed_hold_task
    timed_hold_tasks.max(&:created_at)
  end

  attr_accessor :timed_hold_tasks
  def timed_hold_tasks
    @timed_hold_tasks ||= children.select { |t| t.is_a?(TimedHoldTask) && t.active? }
  end

  private

  def task_is_assigned_to_users_organization?(user)
    assigned_to.is_a?(Organization) && assigned_to.user_has_access?(user)
  end

  class << self
    def create_from_params(params, user)
      parent_task = Task.find(params[:parent_id])
      fail Caseflow::Error::ChildTaskAssignedToSameUser if parent_task.assigned_to_id == params[:assigned_to_id] &&
                                                           parent_task.assigned_to_type == params[:assigned_to_type]

      verify_user_can_create!(user, parent_task)

      params = modify_params(params)
      child = create_child_task(parent_task, user, params)
      parent_task.update!(status: params[:status]) if params[:status]
      child
    end

    def create_child_task(parent, current_user, params)
      transaction do
        parent.update!(status: Constants.TASK_STATUSES.on_hold)

        Task.create!(
          type: name,
          appeal: parent.appeal,
          assigned_by_id: child_assigned_by_id(parent, current_user),
          parent_id: parent.id,
          assigned_to: child_task_assignee(parent, params),
          instructions: params[:instructions]
        )
      end
    end

    def place_on_timed_hold(task, params)
      transaction do
        # Cancel any other hold tasks so we don't wind up with more than one
        task.timed_hold_tasks.each do |t| 
          t.task_timers.each(&:processed!)
          t.update!(status: Constants.TASK_STATUSES.cancelled) 
        end

        TimedHoldTask.create!(
          appeal: task.appeal,
          parent_id: task.id,
          assigned_to: task.parent.assigned_to,
          instructions: params[:instructions],
          on_hold_duration: params[:on_hold_duration]
        )
      end
    end
  end
end
