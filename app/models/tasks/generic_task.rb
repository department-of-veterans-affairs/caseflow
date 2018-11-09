class GenericTask < Task
  def available_actions(user)
    if assigned_to == user
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h
      ]
    end

    if assigned_to.is_a?(Organization) && assigned_to.user_has_access?(user)
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h
      ]
    end

    []
  end

  def update_from_params(params, current_user)
    verify_user_access!(current_user)

    return reassign(params[:reassign], current_user) if params[:reassign]

    new_status = params[:status]
    if new_status == Constants.TASK_STATUSES.completed
      mark_as_complete!
    else
      update!(status: new_status)
    end

    [self]
  end

  def reassign(reassign_params, current_user)
    reassign_params[:instructions] = [instructions, reassign_params[:instructions]].flatten
    sibling = self.class.create_child_task(parent, current_user, reassign_params)
    mark_as_complete!

    children_to_update = children.reject { |t| t.status == Constants.TASK_STATUSES.completed }
    children_to_update.each { |t| t.update!(parent_id: sibling.id) }

    [sibling, self, children_to_update].flatten
  end

  def can_be_accessed_by_user?(user)
    return true if assigned_to && assigned_to == user
    return true if user && assigned_to.is_a?(Organization) && assigned_to.user_has_access?(user)
    false
  end

  class << self
    def create_from_params(params, user)
      parent = Task.find(params[:parent_id])
      fail Caseflow::Error::ChildTaskAssignedToSameUser if parent.assigned_to_id == params[:assigned_to_id] &&
                                                           parent.assigned_to_type == params[:assigned_to_type]

      parent.verify_user_access!(user)

      params = modify_params(params)
      child = create_child_task(parent, user, params)
      update_status(parent, params[:status])
      child
    end

    def create_child_task(parent, current_user, params)
      # Create an assignee from the input arguments so we throw an error if the assignee does not exist.
      assignee = Object.const_get(params[:assigned_to_type]).find(params[:assigned_to_id])

      parent.update!(status: :on_hold)

      Task.create!(
        type: name,
        appeal: parent.appeal,
        assigned_by_id: child_assigned_by_id(parent, current_user),
        parent_id: parent.id,
        assigned_to: assignee,
        instructions: params[:instructions]
      )
    end

    private

    def child_assigned_by_id(parent, current_user)
      return current_user.id if current_user
      return parent.assigned_to_id if parent && parent.assigned_to_type == User.name
    end

    def update_status(parent, status)
      return unless status

      case status
      when Constants.TASK_STATUSES.completed
        parent.mark_as_complete!
      else
        parent.update!(status: status)
      end
    end
  end
end
