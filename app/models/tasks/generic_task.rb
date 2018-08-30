class GenericTask < Task
  # Only request to PATCH /tasks/:id we expect for GenericTasks is to mark the task complete.
  def update_from_params(_params)
    mark_as_complete!
  end

  class << self
    def create_from_params(params, current_user)
      parent = Task.find(params[:parent_id])
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
