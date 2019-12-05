# frozen_string_literal: true

class Tasks::ChangeTypeController < TasksController
  def update
    queue_for_role = QueueForRole.new(user_role).create(user: current_user)
    tasks = task.update_task_type(update_params)
    tasks_to_return = (queue_for_role.tasks + tasks).uniq

    render json: { tasks: json_tasks(tasks_to_return) }
  end

  private

  def task
    @task ||= Task.find(params[:id])
  end

  def update_params
    change_type_params = params.require(:task).permit(:type, :instructions)
    change_type_params[:instructions] = task.flattened_instructions(change_type_params)
    change_type_params
  end
end
