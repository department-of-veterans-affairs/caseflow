# frozen_string_literal: true

class JudgeAssignTasksController < TasksController
  def create
    queue_for_role = QueueForRole.new(user_role).create(user: current_user)
    tasks_to_return = (tasks + queue_for_role.tasks).uniq

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
    ActiveRecord::Base.multi_transaction do
      create_params.map do |create_param|
        judge_assign_task = JudgeAssignTask.find(create_param[:parent_id])
        AttorneyTaskCreator.new(judge_assign_task, create_param).call
      end.flatten
    end
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
