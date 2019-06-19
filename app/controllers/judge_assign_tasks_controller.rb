# frozen_string_literal: true

class JudgeAssignTasksController < TasksController
  def create
    tasks_to_return = (tasks + queue_class.new(user: current_user).tasks).uniq

    render json: { tasks: json_tasks(tasks_to_return) }
  end

  private

  def task_params
    @task_params ||= create_params.first
  end

  def reassign_params
    { assigned_to_id: task_params[:assigned_to_id], assigned_to_type: "User" }
  end

  def task
    @task ||= Task.find(task_params[:parent_id])
  end

  def tasks
    @tasks ||= assignee_is_judge? ? update_tasks : create_tasks
  end

  def create_tasks
    AttorneyDecisionTask.create_many_from_params(create_params, current_user)
  end

  def update_tasks
    update_tasks = task.reassign(reassign_params, current_user)
    update_tasks.each { |tsk| return invalid_record_error(tsk) unless tsk.valid? }
  rescue ActiveRecord::RecordInvalid => error
    invalid_record_error(error.record)
  end

  def assignee_is_judge?
    JudgeTeam.for_judge(User.find(task_params[:assigned_to_id]))
  end
end
