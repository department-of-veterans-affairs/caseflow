# frozen_string_literal: true

class Tasks::ChangeTypeController < TasksController
  def update
    tasks = update_task_type
    tasks.each { |t| return invalid_record_error(t) unless t.valid? }

    tasks_to_return = (queue_class.new(user: current_user).tasks + tasks).uniq

    render json: { tasks: json_tasks(tasks_to_return) }
  end

  private

  def colocated_sibling
    task.dup.tap do |t|
      t.action = update_params[:action]
      t.instructions = [task.instructions, update_params[:instructions]].flatten
      # Will this ever need to be reassigned?
      t.save!
    end
  end

  def update_task_type
    sibling = nil

    if task.is_a? ColocatedTask
      sibling = colocated_sibling
    else
      fail Caseflow::Error::ActionForbiddenError, message: "Can only change task type of colocated or mail tasks"
    end

    task.update!(status: Constants.TASK_STATUSES.cancelled)

    task.children.active.each { |t| t.update!(parent_id: sibling.id) }

    [sibling, task, sibling.children].flatten
  end

  def task
    @task ||= ::Task.find(params[:id])
  end

  def update_params
    params.require(:task).permit(:action, :instructions)
  end
end
