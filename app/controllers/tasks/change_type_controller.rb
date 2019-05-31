# frozen_string_literal: true

class Tasks::ChangeTypeController < TasksController
  def update
    tasks = Task.find(params[:id]).update_task_type(update_params)
    tasks.each { |task_to_check| return invalid_record_error(task_to_check) unless task_to_check.valid? }

    tasks_to_return = (queue_class.new(user: current_user).tasks + tasks).uniq

    render json: { tasks: json_tasks(tasks_to_return) }
  end

  private

  def update_params
    params.require(:task).permit(:action, :instructions)
  end
end
