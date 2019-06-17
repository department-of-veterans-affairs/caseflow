# frozen_string_literal: true

class Tasks::ChangeTypeController < TasksController
  def update
    tasks = task.update_task_type(update_params)
    tasks_to_return = (queue_class.new(user: current_user).tasks + tasks).uniq

    render json: { tasks: json_tasks(tasks_to_return) }
  end

  private

  def task
    @task ||= Task.find(params[:id])
  end

  def update_params
    change_type_params = params.require(:task).permit(:action, :instructions)
    change_type_params[:instructions] = [change_type_params[:instructions], task.instructions].flatten
    change_type_params
  end
end
