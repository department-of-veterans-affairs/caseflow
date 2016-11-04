class TasksController < ApplicationController
  before_action :verify_access

  def index
    @tasks = Task.find_by_department(department).order(created_at: :desc).all
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

  def verify_access
    verify_authorized_roles('Dispatch Tasks')
  end
end
