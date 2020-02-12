# frozen_string_literal: true

class Tasks::EndHoldController < TasksController
  def create
    task.cancel_timed_hold

    render json: { tasks: json_tasks(task.appeal.tasks.includes(*task_includes)) }
  rescue ActiveRecord::RecordInvalid => error
    invalid_record_error(error.record)
  end

  private

  def task
    @task ||= Task.find(params[:task_id])
  end

  def create_params
    params.merge(type: task.type)
  end
end
