# frozen_string_literal: true

class AssignTasksController < TasksController
  def create
    tasks = nil

    if assignee_is_judge?
      @task = Task.find(create_params.first[:parent_id])
      tasks = task.update_from_params(update_params, current_user)
      tasks.each { |t| return invalid_record_error(t) unless t.valid? }
    else
      tasks = AttorneyTask.create_many_from_params(create_params, current_user)
    end

    tasks_to_return = (queue_class.new(user: current_user).tasks + tasks).uniq

    render json: { tasks: json_tasks(tasks_to_return) }
  rescue ActiveRecord::RecordInvalid => error
    invalid_record_error(error.record)
  end

  private

  def assignee_is_judge?
    JudgeTeam.for_judge(User.find(create_params.first[:assigned_to_id]))
  end
end
