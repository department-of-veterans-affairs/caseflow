class TasksController < ApplicationController
  before_action :verify_access

  class TaskTypeMissingError < StandardError; end

  def index
    @completed_count = Task.completed_today.count
    @to_complete_count = Task.to_complete.count
    render index_template
  end

  def show
  end

  def assign
    next_unassigned_task.assign!(current_user)
    redirect_to next_unassigned_task.url_path
  end

  private

  def current_user_historical_tasks
    current_user.tasks.completed.newest_first.limit(10)
  end
  helper_method :current_user_historical_tasks

  def next_unassigned_task
    @next_unassigned_task ||= scoped_tasks.unassigned.first
  end
  helper_method :next_unassigned_task

  def scoped_tasks
    Task.where(type: type).newest_first
  end

  # If a task_type is explicitly passed via the router, use that.
  # Otherwise look up the task type from the task itself
  # Ex:  PATCH /tasks/:id/assign will look up the task type from the task
  def type
    params[:task_type]
  end

  def task_id
    params[:id]
  end

  def task
    @task ||= Task.find(task_id)
  end
  helper_method :task

  def completed_tasks
    @completed_tasks ||= Task.where.not(completed_at: nil).order(created_at: :desc).limit(5)
  end
  helper_method :completed_tasks

  def to_complete_tasks
    @to_complete_tasks ||= Task.to_complete.order(created_at: :desc).limit(5)
  end
  helper_method :to_complete_tasks

  def index_template
    prefix = manager? ? "manager" : "worker"
    "#{prefix}_index"
  end

  def task_roles
    User::TASK_TYPE_TO_ROLES[type] || fail(TaskTypeMissingError)
  end

  def manager?
    # TODO(jd): Determine real CSS role to be used
    current_user.can?(task_roles[:manager])
  end

  def verify_access
    # TODO(jd): Determine real CSS role to be used
    verify_authorized_roles(task_roles[:employee])
  end
end
