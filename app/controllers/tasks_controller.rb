class TasksController < ApplicationController
  before_action :verify_access

  def index
    render index_template
  end

  private

  def next_unassigned_task
    @next_unassigned_task ||= scoped_tasks.unassigned.first
  end
  helper_method :next_unassigned_task

  def scoped_tasks
    Task.find_by_url(request.fullpath).newest_first
  end

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
    current_user.can?(User::ROLES[request.fullpath][:manager])
  end

  def verify_access
    # TODO(jd): Determine real CSS role to be used
    verify_authorized_roles(User::ROLES[request.fullpath][:employee])
  end
end
