class TasksController < ApplicationController
  before_action :verify_access

  def index
    @completed_count = Task.completed_today.count
    @to_complete_count = Task.to_complete.count
    render index_template
  end

  def show
    @task = Task.find(task_id)
  end

  private

  def department
    params[:department]
  end

  def task_id
    params[:id]
  end

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

  def manager?
    # TODO(jd): Determine real CSS role to be used
    current_user.can?("manage #{department}")
  end

  def verify_access
    # TODO(jd): Determine real CSS role to be used
    verify_authorized_roles(department.to_s)
  end
end
