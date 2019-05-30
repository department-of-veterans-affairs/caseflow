# frozen_string_literal: true

class Tasks::ChangeTypeController < TasksController
  def update
    tasks = update_task_type
    tasks.each { |task_to_check| return invalid_record_error(task_to_check) unless task_to_check.valid? }

    tasks_to_return = (queue_class.new(user: current_user).tasks + tasks).uniq

    render json: { tasks: json_tasks(tasks_to_return) }
  end

  private

  def colocated_sibling
    task.dup.tap do |dupe|
      dupe.action = update_params[:action]
      dupe.instructions = [task.instructions, update_params[:instructions]].flatten
      # Will this ever need to be reassigned?
      dupe.save!
    end
  end

  def mail_sibling
    new_class = MailTask.subclasses.find { |mt| mt.name == update_params[:action] }

    new_assignee = task.assigned_to
    if new_class.respond_to? :default_assignee
      new_assignee = new_class.default_assignee(task.parent, update_params)
    end

    new_class.create!(
      appeal: task.appeal,
      assigned_to: new_assignee,
      assigned_by: task.assigned_by,
      instructions: [task.instructions, update_params[:instructions]].flatten,
      status: task.status,
      parent: task.parent
      # on_hold_duration: task.on_hold_duration, ??
      # placed_on_hold_at: task.placed_on_hold_at, ??
      # started_at: task.started_at, ??
    )
  end

  def update_task_type
    sibling = nil

    if task.is_a? ColocatedTask
      sibling = colocated_sibling
    elsif task.is_a? MailTask
      sibling = mail_sibling
    else
      fail Caseflow::Error::ActionForbiddenError, message: "Can only change task type of colocated or mail tasks"
    end

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
