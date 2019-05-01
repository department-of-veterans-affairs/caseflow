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

    if appeal.tasks.active.where(
      type: type,
      assigned_to: assigned_to,
      parent: parent
    ).any? && assigned_to.is_a?(Organization)
      fail(
        Caseflow::Error::DuplicateOrgTask,
        appeal_id: appeal.id,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name,
        parent_id: parent&.id
      )
    end
  end
  def available_actions(user)
    return [] unless user

    base_actions = [
      Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
      Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
      Constants.TASK_ACTIONS.CANCEL_TASK.to_h
    ]
    if assigned_to == user
      base_actions.push(Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h)
      return lit_support_user(user, base_actions)
    end

    if task_is_assigned_to_user_within_organization?(user)
      return [
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h
      ]
    end

    if task_is_assigned_to_users_organization?(user)
      base_actions.push(Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h)
      return mail_task_for_lit_support_org(base_actions)
    end

    []
  end

  private

  def mail_task_types_for_lit_support
    %w[ReconsiderationMotionMailTask ClearAndUnmistakeableErrorMailTask VacateMotionMailTask]
  end

  def appropriate_mail_tasks_and_assigned_to_lit_support
    (mail_task_types_for_lit_support.include? type) && (assigned_to.name == Constants.LIT_SUPPORT.ORG_NAME)
  end

  def mail_task_for_lit_support_org(base_actions)
    if appropriate_mail_tasks_and_assigned_to_lit_support
      base_actions.push(Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h)
    end
    base_actions
  end

  def lit_support_user(user, base_actions)
    if user.roles.include? Constants.LIT_SUPPORT.USER_ROLE
      base_actions.push(Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h)
    end
    base_actions
  end

  def task_is_assigned_to_users_organization?(user)
    assigned_to.is_a?(Organization) && assigned_to.user_has_access?(user)
  end

  def assign_to_pulac_cerullo(user)
    Task.create!(
      type: type,
      appeal: self.appeal,
      assigned_by_id: user.id,
      parent_id: self.id,
      assigned_to: PulacCurello.singleton
    )
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
end
