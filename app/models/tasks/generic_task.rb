class GenericTask < Task
  def create_from_params(params)
    create_child_task(params)
    update_status(params[:status])
  end

  # Only request to PATCH /tasks/:id we expect for GenericTasks is to mark the task complete.
  def update_from_params(_params)
    mark_as_complete!
  end

  private

  def create_child_task(params)
    # Create an assignee from the input arguments so we throw an error if the assignee does not exist.
    assignee = Object.const_get(params[:assigned_to_type]).find(params[:assigned_to_id])
    parent = Task.find(params[:parent_id])

    GenericTask.create!(
      appeal: parent.appeal,
      assigned_by_id: parent.assigned_to_id,
      parent_id: parent.id,
      assigned_to: assignee
    )
  end

  def update_status(status)
    return unless status

    case status
    when "completed"
      mark_as_complete!
    else
      update!(status: status)
    end
  end
end
