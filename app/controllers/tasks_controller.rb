class TasksController < ApplicationController
  before_action :verify_access
  before_action :verify_assigned_to_current_user, only: [:show]

  class TaskTypeMissingError < StandardError; end

  def index
    @completed_count = Task.completed_today.count
    @to_complete_count = Task.to_complete.count
    render index_template
  end

  def show
  end

  def assign
    if Task.user_current_task(current_user).count > 0
      user_task = Task.user_current_task(current_user).first
    else
      user_task = next_unassigned_task
      user_task.assign!(current_user)
    end
    redirect_to url_for(user_task)
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
    current_user.can?(task_roles[:manager])
  end

  def verify_access
    verify_authorized_roles(task_roles[:employee])
  end

  def verify_assigned_to_current_user
    verify_user(task.user)
  end
end
