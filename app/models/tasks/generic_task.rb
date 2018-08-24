class GenericTask < Task
  # Only request to PATCH /tasks/:id we expect for GenericTasks is to mark the task complete.
  def update_from_params(_params)
    mark_as_complete!
  end

  class << self
    def create_from_params(params)
      parent = Task.find(params[:parent_id])
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
