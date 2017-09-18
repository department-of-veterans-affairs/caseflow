class EstablishClaimsController < TasksController
  before_action :verify_access
  before_action :verify_assigned_to_current_user, only: [:show, :pdf, :cancel, :perform]
  before_action :verify_not_complete, only: [:perform, :update_appeal]
  before_action :verify_bgs_info_valid, only: [:perform]
  before_action :verify_manager_access, only: [
    :unprepared_tasks,
    :update_employee_count,
    :canceled_tasks,
    :work_assignments
  ]

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
    assigned_task = tasks.assign_next_to!(current_user)

    return not_found unless assigned_task
    render json: { next_task_id: assigned_task.id }
  end

  def perform
    # If we've already created the EP, no-op and send the user to the note page
    task.perform!(establish_claim_params) unless task.reviewed?
    render json: {}

  rescue EstablishClaim::VBMSError => e
    render json: { error_code: e.error_code }, status: 422
  end

  # This POST updates VACOLS & VBMS Note
  def review_complete
    task.complete_with_review!(review_complete_params)
    render json: {}
  end

  def email_complete
    task.complete_with_email!(email_params)
    render json: {}
  end

  def assign_existing_end_product
    task.assign_existing_end_product!(params[:end_product_id])
    render json: {}
  end

  def update_employee_count
    team_quota.update!(user_count: params[:count])

    render json: team_quota.user_quotas.map(&:to_hash)
  end

  def cancel
    Task.transaction do
      task.appeal.update!(special_issues_params) if params[:special_issues]
      task.cancel!(cancel_feedback)
    end

    render json: {}
  end

  # Index of all tasks that are unprepared at least 1 day
  def unprepared_tasks
    @unprepared_tasks = EstablishClaim.unprepared.oldest_first.select do |task|
      (Time.zone.now - task.created_at).to_i / 1.day > 0
    end
  end

  def canceled_tasks
    @canceled_tasks = EstablishClaim.past_weeks(5).canceled.newest_first
  end

  private

  def verify_bgs_info_valid
    return true if task.bgs_info_valid?
    render json: { error_code: "bgs_info_invalid" }, status: 422
  end

  def to_complete_count
    tasks.to_complete.count
  end
  helper_method :to_complete_count

  def current_user_historical_tasks
    tasks.completed_by(current_user).newest_first.joins_task_result.limit(10)
  end
  helper_method :current_user_historical_tasks

  def start_text
    "Establish next claim"
  end
  helper_method :start_text

  def tasks
    EstablishClaim
  end
  helper_method :tasks

  def verify_manager_access
    verify_authorized_roles("Manage Claim Establishment")
  end

  def manager?
    current_user.can?("Manage Claim Establishment")
  end

  def verify_access
    manager? || verify_authorized_roles("Establish Claim")
  end

  def logo_name
    "Dispatch"
  end

  def logo_path
    establish_claims_path
  end

  def set_application
    RequestStore.store[:application] = "dispatch-arc"
  end

  def team_quota
    @team_quota ||= tasks.todays_quota
  end
  helper_method :team_quota

  def user_quota
    @user_quota ||= team_quota.assigned_quotas.find_by(user: current_user)
  end
  helper_method :user_quota

  def review_complete_params
    { vacols_note: params[:vacols_note] }
  end

  def email_params
    { email_ro_id: params[:email_ro_id], email_recipient: params[:email_recipient] }
  end

  def establish_claim_params
    params.require(:claim)
          .permit(:end_product_code, :end_product_label, :end_product_modifier, :gulf_war_registry,
                  :suppress_acknowledgement_letter, :station_of_jurisdiction, :date)
  end

  def special_issues_params
    params.require(:special_issues).permit(*Appeal::SPECIAL_ISSUES.keys)
  end

  def cancel_feedback
    params.require(:feedback)
  end

  def total_cases_completed
    user_quota ? user_quota.tasks_completed_count : 0
  end
  helper_method :total_cases_completed
end
