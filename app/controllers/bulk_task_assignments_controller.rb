# frozen_string_literal: true

class BulkTaskAssignmentsController < TasksController
  def create
    bulk_task_assignment = BulkTaskAssignment.new(*bulk_task_assignment_params)
    return invalid_record_error(bulk_task_assignment) unless bulk_task_assignment.valid?

    bulk_task_assignment.process

    render json: { queue_config: QueueConfig.new(assignee: organization).to_hash }
  end

  def organization
    Organization.find_by(url: params[:bulk_task_assignment][:organization_url])
  end

  private

  def bulk_task_assignment_params
    params.require(:bulk_task_assignment)
      .permit(:assigned_to_id, :organization_url, :task_type, :regional_office, :task_count)
      .merge(assigned_by: current_user)
  end

  def task_classes
    [bulk_task_assignment_params[:task_type].to_sym]
  end
end
