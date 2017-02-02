class TasksController < ApplicationController
  before_action :verify_access
  before_action :verify_assigned_to_current_user, only: [:show, :pdf, :cancel]

  class TaskTypeMissingError < StandardError; end

  TASKS_PER_PAGE = 10

  def index
    respond_to do |format|
      format.html do
        @completed_count_today = Task.completed_today.count
        @to_complete_count = Task.to_complete.count
        render index_template
      end

      format.json do
        render json: {
          completedTasks: completed_tasks.map(&:to_hash),
          completedCountTotal: completed_count_total
        }
      end
    end
  end

  def show
    start_task!

    return render "canceled" if task.canceled?
    return render "assigned_existing_ep" if task.assigned_existing_ep?
    return render "complete" if task.completed?

    # TODO: Reassess the best way to handle decision errors
    return render "no_decisions" if task.appeal.decision.nil?
  rescue Appeal::MultipleDecisionError
    render "multiple_decisions"
  end

  def pdf
    decision = task.appeal.decision
    return redirect_to "/404" if decision.nil?
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

  def cancel
    task.cancel!(cancel_feedback)

    respond_to do |format|
      format.html { redirect_to establish_claims_path }
      format.json { render json: {} }
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

  def offset
    # When no page param exists, it will cast the nil page to zero
    # effectively providing no offset on page initial load
    TASKS_PER_PAGE * params[:page].to_i
  end

  # This is to account for tasks that have been completed since initial
  # page load. By calculating the difference between the total completed on initial
  # page load and at the time of clicking "Show More", we can figure out
  # the proper offset to use to achieve the "next" 10
  def completed_tasks_offset_diff
    expected_total = params[:expectedCompletedTotal].to_i
    # Return if we don't have a true expected total to diff against
    return 0 if expected_total.zero?

    completed_count_total - expected_total.to_i
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

  def completed_count_total
    @completed_count_total ||= Task.completed.count
  end
  helper_method :completed_count_total

  def completed_tasks
    @completed_tasks ||= begin
      computed_offset = completed_tasks_offset_diff + offset

      Task.completed
          .newest_first(:completed_at)
          .offset(computed_offset)
          .limit(TASKS_PER_PAGE)
    end
  end
  helper_method :completed_tasks

  def current_tasks
    @current_tasks ||= Task.assigned_not_completed.newest_first
  end
  helper_method :current_tasks

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
