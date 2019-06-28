# frozen_string_literal: true

class BulkTaskAssignmentsController < TasksController
  def create
    bulk_task_assignment = BulkTaskAssignment.new(*bulk_task_assignment_params)
    return invalid_record_error(bulk_task_assignment) unless bulk_task_assignment.valid?

    tasks = bulk_task_assignment.process

    render json: json_tasks(tasks)
  end

  private

  def bulk_task_assignment_params
    params.require(:bulk_task_assignment)
      .permit(:assigned_to_id, :organization_url, :task_type, :regional_office, :task_count)
      .merge(assigned_by: current_user)
  end
end
