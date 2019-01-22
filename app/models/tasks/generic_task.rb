class GenericTask < Task
  before_create :verify_org_task_unique

  # Use the existence of an organization-level task to prevent duplicates since there should only ever be one org-level
  # task active at a time for a single appeal.
  def verify_org_task_unique
    if Task.where(type: type, assigned_to: assigned_to, appeal: appeal)
        .where.not(status: Constants.TASK_STATUSES.completed).any? &&
       assigned_to.is_a?(Organization)
      fail(
        Caseflow::Error::DuplicateOrgTask,
        appeal_id: appeal.id,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name
      )
    end
  end

  # rubocop:disable Metrics/MethodLength
  def available_actions(user)
    return [] unless user

    if assigned_to == user
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h
      ]
    end

    if task_is_assigned_to_user_within_organiztaion?(user)
      return [
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h
      ]
    end

    if task_is_assigned_to_users_organization?(user)
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h
      ]
    end

    []
  end
  # rubocop:enable Metrics/MethodLength

  def update_from_params(params, current_user)
    verify_user_can_update!(current_user)

    return reassign(params[:reassign], current_user) if params[:reassign]

    update!(status: params[:status]) if params[:status]

    [self]
  end

  def reassign(reassign_params, current_user)
    reassign_params[:instructions] = [instructions, reassign_params[:instructions]].flatten
    sibling = self.class.create_child_task(parent, current_user, reassign_params)
    update!(status: Constants.TASK_STATUSES.completed)

    children_to_update = children.reject { |t| t.status == Constants.TASK_STATUSES.completed }
    children_to_update.each { |t| t.update!(parent_id: sibling.id) }

    [sibling, self, children_to_update].flatten
  end

  def can_be_updated_by_user?(user)
    available_actions_unwrapper(user).any?
  end

  private

  def task_is_assigned_to_user_within_organiztaion?(user)
    parent&.assigned_to.is_a?(Organization) &&
      assigned_to.is_a?(User) &&
      parent.assigned_to.user_has_access?(user)
  end

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

    def child_task_assignee(_parent, params)
      Object.const_get(params[:assigned_to_type]).find(params[:assigned_to_id])
    end

    def child_assigned_by_id(parent, current_user)
      return current_user.id if current_user
      return parent.assigned_to_id if parent && parent.assigned_to_type == User.name
    end
  end
end
