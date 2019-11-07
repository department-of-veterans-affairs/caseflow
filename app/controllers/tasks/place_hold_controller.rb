# frozen_string_literal: true

class Tasks::PlaceHoldController < TasksController
  def create
    TimedHoldTask.create_from_parent(task, **create_params.to_h.symbolize_keys.except(:type))

    render json: { tasks: json_tasks(task.appeal.tasks.includes(*task_includes)) }
  rescue ActiveRecord::RecordInvalid => error
    invalid_record_error(error.record)
  end

  private

  def task
    @task ||= ::Task.find(params[:task_id])
  end

  def create_params
    params.require(:task).permit(:days_on_hold, :instructions).merge(assigned_by: current_user, type: task.type)
  end
end
