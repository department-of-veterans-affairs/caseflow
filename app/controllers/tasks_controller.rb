# Some generic task helper methods.
# TODO: When second type of task is added, see what other logic
#       from EstablishClaimsController can be abstracted out
class TasksController < ApplicationController
  class InvalidTaskClassError < StandardError; end
  class InvalidTaskStateError < StandardError; end

  before_action :check_dispatch_out_of_service
  before_action :verify_admin_access, only: [:index]

  TASK_CLASSES = {
    EstablishClaim: EstablishClaim
  }.freeze

  # API for returning task information
  # Params:
  #   state -  filters tasks by a certain state (e.g. unassigned)
  #   type  -  filters tasks by a certain task subclass (e.g. EstablishClaim)
  def index
    render json: {
      tasks: tasks.map(&:to_hash)
    }
  end

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

  def tasks
    @tasks ||= task_class.method(task_state).call.oldest_first.limit(10)
  end

  def verify_admin_access
    verify_authorized_roles(task_class::ADMIN_FUNCTION)
  end

  def task_state
    state = params[:state].try(:to_sym)
    task_states.include?(state) ? state : fail(InvalidTaskStateError)
  end

  def task_class
    TASK_CLASSES[params[:type].try(:to_sym)] || fail(InvalidTaskClassError)
  end

  def task_states
    task_class.aasm.states.map(&:name)
  end
end
