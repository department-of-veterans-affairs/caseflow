class TasksController < ApplicationController
  before_action :verify_access

  def index
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
