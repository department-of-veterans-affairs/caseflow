# frozen_string_literal: true

class Tasks::BulkAssignController < TasksController
  def create
    result = TaskBulkCreator.new(create_params).create

    if result.success?
      render json: { tasks: result.extra }
    else
      render json: result.to_h, status: :bad_request
    end
  end

  private

  def create_params
    params.require(:bulk_assign)
      .permit(:assigned_to_id, :number_of_tasks, parent_ids: [])
      .merge(assigned_by: current_user)
  end
end
