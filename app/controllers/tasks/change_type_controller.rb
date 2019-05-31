# frozen_string_literal: true

class Tasks::ChangeTypeController < TasksController
  def update
    tasks = update_task_type(Task.find(params[:id]), update_params)
    tasks.each { |task_to_check| return invalid_record_error(task_to_check) unless task_to_check.valid? }

    tasks_to_return = (queue_class.new(user: current_user).tasks + tasks).uniq

    render json: { tasks: json_tasks(tasks_to_return) }
  end

  private

  def update_task_type(task, params)
    sibling = task.change_type(params)
    task.update!(status: Constants.TASK_STATUSES.cancelled)
    task.children.active.each { |child| child.update!(parent_id: sibling.id) }

    parents = []

    if task.parent.slice(:class, :action, :type).eql? task.slice(:class, :action, :type)
      parents << update_task_type(task.parent, params)
    end

    [sibling, task, sibling.children, parents].flatten
  end

  def update_params
    params.require(:task).permit(:action, :instructions)
  end
end
