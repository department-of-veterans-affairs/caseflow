class TasksController < ApplicationController
  before_action :verify_access

  def index
    render index_template
  end

  private

  def department
    params[:department]
  end

  def task_id
    params[:id]
  end

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
