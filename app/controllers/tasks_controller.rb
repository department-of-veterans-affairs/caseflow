class TasksController < ApplicationController
  before_action :verify_access, except: [:unprepared_tasks, :update_employee_count]
  before_action :verify_assigned_to_current_user, only: [:show, :pdf, :cancel]

  class TaskTypeMissingError < StandardError; end

  TASKS_PER_PAGE = 10

  def index
    tasks_completed_today = Task.completed_today
    @completed_count_today = tasks_completed_today.count
    @to_complete_count = Task.to_complete.count
    @tasks_completed_by_users = Task.tasks_completed_by_users(tasks_completed_today)

    render index_template
  end

  def show
    start_task!

    return render "canceled" if task.canceled?
    return render "assigned_existing_ep" if task.assigned_existing_ep?
    return render "complete" if task.completed?

    # TODO: Reassess the best way to handle decision errors
    return render "no_decisions" if task.appeal.decisions.nil?
  end

  def pdf
    return redirect_to "/404" if task.appeal.decisions.nil? || task.appeal.decisions.size == 0
    decision_number = params[:decision_number].to_i
    return redirect_to "/404" if decision_number >= task.appeal.decisions.size || decision_number < 0
    decision = task.appeal.decisions[decision_number]
    send_file(decision.serve, type: "application/pdf", disposition: "inline")
  end

  def assign
    # Doesn't assign if user has a task of the same type already assigned.
    next_task = current_user_next_task
    return not_found unless next_task

    next_task.assign!(:assigned, current_user) if next_task.may_assign?

    respond_to do |format|
      format.html do
        return redirect_to url_for(action: next_task.initial_action, id: next_task.id)
      end
      format.json do
        return render json: { next_task_id: next_task.id }
      end
    end
  end

  private

  def current_user_historical_tasks
    current_user.tasks.completed.newest_first.limit(10)
  end
  helper_method :current_user_historical_tasks

  def next_unassigned_task
    @next_unassigned_task ||= scoped_tasks.unassigned.to_complete.first
  end
  helper_method :next_unassigned_task

  # This method returns the next task this user should work on. Either,
  # a previously assigned task that was never completed, or a new
  # unassigned task.
  def current_user_next_task
    current_user.tasks.to_complete.where(type: type).first || next_unassigned_task
  end
  helper_method :current_user_next_task

  def scoped_tasks
    Task.where(type: type).oldest_first
  end

  def type
    params[:task_type] || (task && task.type.to_sym)
  end

  def start_text
    type.to_s.titlecase
  end
  helper_method :start_text

  def task_id
    params[:id]
  end

  def task
    @task ||= Task.find(task_id)
  end
  helper_method :task

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
    manager? or verify_authorized_roles(task_roles[:employee])
  end

  def verify_assigned_to_current_user
    verify_user(task.user)
  end

  def logo_name
    "Dispatch"
  end

  def verify_not_complete
    return true unless task.completed?

    redirect_to complete_establish_claim_path(task)
  end

  def cancel_feedback
    params.require(:feedback)
  end

  def start_task!
    # Future safeguard for when we give managers a show view
    # for a given task
    task.start! if current_user == task.user && task.may_start?
  end
end
