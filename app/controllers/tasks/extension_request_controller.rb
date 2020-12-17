# frozen_string_literal: true

class Tasks::ExtensionRequestController < TasksController
  def create
    send create_params[:decision]
  end

  def grant
    # TODO: Record grant
    TimedHoldTask.create_from_parent(task, **create_params.to_h.symbolize_keys.except(:decision))

    render json: {}
  rescue ActiveRecord::RecordInvalid => error
    invalid_record_error(error.record)
  end

  def deny
    # TODO: record deny

    render json: {}
  end

  private

  def task
    @task ||= ::Task.find(params[:task_id])
  end

  def create_params
    params.require(:task).permit(:decision, :days_on_hold, :instructions).merge(assigned_by: current_user)
  end
end
