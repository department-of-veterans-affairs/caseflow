class GenericTask < Task
  # Only request to PATCH /tasks/:id we expect for GenericTasks is to mark the task complete.
  def update_from_params(_params, current_user)
    verify_user_access(current_user)
    mark_as_complete!
  end

  def verify_user_access(user)
    return if assigned_to && assigned_to == user

    unless user && assigned_to.class.method_defined?(:user_has_access?) && assigned_to.user_has_access?(user)
      fail Caseflow::Error::ActionForbiddenError, message: "Current user cannot act on this task"
    end
  end

  class << self
    def create_from_params(params, current_user)
      parent = Task.find(params[:parent_id])
      parent.verify_user_access(current_user)

      child = create_child_task(parent, current_user, params)
      update_status(parent, params[:status])
      child
    end

    private

    def create_child_task(parent, current_user, params)
      # Create an assignee from the input arguments so we throw an error if the assignee does not exist.
      assignee = Object.const_get(params[:assigned_to_type]).find(params[:assigned_to_id])

      GenericTask.create!(
        appeal: parent.appeal,
        assigned_by_id: child_assigned_by_id(parent, current_user),
        parent_id: parent.id,
        assigned_to: assignee
      )
    end

    def child_assigned_by_id(parent, current_user)
      return current_user.id if current_user
      return parent.assigned_to_id if parent && parent.assigned_to_type == User.name
    end

    def update_status(parent, status)
      return unless status

      case status
      when "completed"
        parent.mark_as_complete!
      else
        parent.update!(status: status)
      end
    end
  end
end
