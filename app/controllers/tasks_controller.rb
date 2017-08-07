# Some generic task helper methods.
# TODO: When second type of task is added, see what other logic
#       from EstablishClaimsController can be abstracted out
class TasksController < ApplicationController
  class TaskTypeMissingError < StandardError; end
  before_action :check_dispatch_out_of_service

  private

  def check_dispatch_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("dispatch_out_of_service")
  end

  # Future safeguard for when we give managers a show view for a given task
  def start_task!
    task.start! if current_user == task.user && task.may_start?
  end

  def verify_assigned_to_current_user
    verify_user(task.user)
  end

  def verify_not_complete
    return true unless task.completed?
    render json: { error_code: "task_already_completed" }, status: 422
  end

  def task_id
    params[:id]
  end

  def task
    @task ||= Task.find(task_id)
  end
  helper_method :task
end
