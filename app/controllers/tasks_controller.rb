class TasksController < ApplicationController
  before_action :verify_access, except: [:unprepared_tasks, :update_employee_count]
  before_action :verify_assigned_to_current_user, only: [:show, :pdf, :cancel]

  class TaskTypeMissingError < StandardError; end

  TASKS_PER_PAGE = 10

  def index
    @tasks_completed_today = Task.completed_today
    @remaining_count_today = Task.to_complete.count
    @completed_count_today = @tasks_completed_today.count
    @to_complete_count = Task.to_complete.count
    @tasks_completed_by_users = Task.tasks_completed_by_users(@tasks_completed_today)

    render index_template
  end

  def update_appeal
    task.appeal.update!(special_issues_params)
    render json: {}
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

    render json: { next_task_id: next_task.id }
  end

  private

  def user_completed_today
    current_user ? Task.completed_today_by_user(current_user.id).count : 0
  end
  helper_method :user_completed_today

  def to_complete_count
    Task.to_complete.count
  end
  helper_method :to_complete_count

  def current_user_historical_tasks
    current_user.tasks.completed.newest_first.limit(10)
  end
  helper_method :current_user_historical_tasks

  # Before assigning the next task to the current user, we want to check and
  # verify they have the right sensitivity level to access that case. If they
  # don't, we skip it and move on to the next case
  def next_unassigned_task
    @next_unassigned_task ||= scoped_tasks.unassigned.to_complete.find do |task|
      task.appeal.can_be_accessed_by_current_user?
    end
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
    manager? || verify_authorized_roles(task_roles[:employee])
  end

  def verify_assigned_to_current_user
    verify_user(task.user)
  end

  def logo_name
    "Dispatch"
  end

  def verify_not_complete
    return true unless task.completed?
    render json: { error_code: "task_already_completed" }, status: 422
  end

  def cancel_feedback
    params.require(:feedback)
  end

  def start_task!
    # Future safeguard for when we give managers a show view
    # for a given task
    task.start! if current_user == task.user && task.may_start?
  end

  def special_issues_params
    params.require(:special_issues).permit(:contaminated_water_at_camp_lejeune,
                                           :dic_death_or_accrued_benefits_united_states,
                                           :education_gi_bill_dependents_educational_assistance_scholars,
                                           :foreign_claim_compensation_claims_dual_claims_appeals,
                                           :foreign_pension_dic_all_other_foreign_countries,
                                           :foreign_pension_dic_mexico_central_and_south_america_caribb,
                                           :hearing_including_travel_board_video_conference,
                                           :home_loan_guaranty, :incarcerated_veterans, :insurance,
                                           :manlincon_compliance, :mustard_gas, :national_cemetery_administration,
                                           :nonrating_issue, :pension_united_states, :private_attorney_or_agent,
                                           :radiation, :rice_compliance, :spina_bifida,
                                           :us_territory_claim_american_samoa_guam_northern_mariana_isla,
                                           :us_territory_claim_philippines,
                                           :us_territory_claim_puerto_rico_and_virgin_islands,
                                           :vamc, :vocational_rehab, :waiver_of_overpayment)
  end
end
