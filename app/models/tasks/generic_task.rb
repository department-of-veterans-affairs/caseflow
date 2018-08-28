class GenericTask < Task
  # Only request to PATCH /tasks/:id we expect for GenericTasks is to mark the task complete.
  def update_from_params(_params)
    verify_user_access
    mark_as_complete!
  end

  def verify_user_access
    u = RequestStore.store[:current_user]
    return if assigned_to && assigned_to == u

    unless u && assigned_to.class.method_defined?(:user_has_access?) && assigned_to.user_has_access?(u)
      fail Caseflow::Error::ActionForbiddenError, message: "Current user cannot act on this task"
    end
  end

  class << self
    def create_from_params(params)
      parent = Task.find(params[:parent_id])
      parent.verify_user_access

      create_child_task(parent, params)
      update_status(parent, params[:status])
    end

    private

    def create_child_task(parent, params)
      # Create an assignee from the input arguments so we throw an error if the assignee does not exist.
      assignee = Object.const_get(params[:assigned_to_type]).find(params[:assigned_to_id])

      GenericTask.create!(
        appeal: parent.appeal,
        assigned_by_id: parent.assigned_to_id,
        parent_id: parent.id,
        assigned_to: assignee
      )
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
