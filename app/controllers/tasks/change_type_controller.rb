# frozen_string_literal: true

class Tasks::ChangeTypeController < TasksController
  def update
    tasks = update_task_type
    tasks.each { |task_to_check| return invalid_record_error(task_to_check) unless task_to_check.valid? }

    tasks_to_return = (queue_class.new(user: current_user).tasks + tasks).uniq

    render json: { tasks: json_tasks(tasks_to_return) }
  end

  private

  def update_task_type
    sibling = task.change_type(update_params)
    task.update!(status: Constants.TASK_STATUSES.cancelled)
    task.children.active.each { |child| child.update!(parent_id: sibling.id) }

    [sibling, task, sibling.children].flatten
  end

  def task
    @task ||= ::Task.find(params[:id])
  end

  def update_params
    params.require(:task).permit(:action, :instructions)
  end
end
