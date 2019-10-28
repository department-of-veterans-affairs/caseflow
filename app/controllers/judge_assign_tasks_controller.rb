# frozen_string_literal: true

class JudgeAssignTasksController < TasksController
  def create
    queue_for_role = QueueForRole.new(user_role).create(user: current_user)
    tasks_to_return = (tasks + queue_for_role.tasks).uniq

    render json: { tasks: json_tasks(tasks_to_return) }
  end

  private

  def tasks
    @tasks ||= ActiveRecord::Base.multi_transaction do
      create_params.map do |create_param|
        judge_assign_task = JudgeAssignTask.find(create_param[:parent_id])
        AttorneyTaskCreator.new(judge_assign_task, create_param).call
      end.flatten
    end
  end
end
