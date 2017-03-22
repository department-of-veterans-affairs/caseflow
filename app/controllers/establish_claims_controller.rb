class EstablishClaimsController < TasksController
  before_action :verify_assigned_to_current_user, only: [:show, :pdf, :cancel, :perform]
  before_action :verify_not_complete, only: [:perform]
  before_action :verify_manager_access, only: [:unprepared_tasks, :update_employee_count]
  before_action :set_application

  def perform
    # If we've already created the EP, we want to send the user to the note page
    return render json: {} if task.reviewed?

    Task.transaction do
      task.appeal.update!(appeal_params)
      Dispatch.new(claim: establish_claim_params, task: task).establish_claim!
    end
    render json: {}
  end

  # This POST updates VACOLS & VBMS Note
  def review_complete
    Task.transaction do
      Dispatch.new(task: task, vacols_note: vacols_note_params).update_vacols!
      task.complete!(status: 0)
      task.claim_establishment.update!(decision_date: Time.now) if task.claim_establishment
    end
    render json: {}
  end

  def email_complete
    task.complete!(status: Task.completion_status_code(:special_issue_emailed))
    task.claim_establishment.update!(decision_date: Time.now) if task.claim_establishment
    render json: {}
  end

  def no_email_complete
    task.complete!(status: Task.completion_status_code(:special_issue_not_emailed))
    task.claim_establishment.update!(decision_date: Time.now) if task.claim_establishment
    render json: {}
  end

  def assign_existing_end_product
    Dispatch.new(task: task)
            .assign_existing_end_product!(end_product_id: params[:end_product_id],
                                          special_issues: special_issues_params)
    task.claim_establishment.update!(decision_date: Time.now) if task.claim_establishment
    render json: {}
  end

  def update_employee_count
    Rails.cache.write("employee_count", params[:count])
    render json: {}
  end

  def total_assigned_issues
    if Rails.cache.read("employee_count").to_i == 0 || Rails.cache.read("employee_count").nil?
      per_employee_quota = 0
    else
      employee_total = Rails.cache.read("employee_count").to_i
      per_employee_quota = (@completed_count_today + @remaining_count_today) /
                           employee_total
    end
    per_employee_quota
  end
  helper_method :total_assigned_issues

  def cancel
    Task.transaction do
      task.appeal.update!(special_issues_params) if params[:special_issues]
      task.cancel!(cancel_feedback)
    end

    render json: {}
  end

  def unprepared_tasks
    @unprepared_tasks ||= EstablishClaim.unprepared.oldest_first
  end

  def verify_manager_access
    verify_authorized_roles("Manage Claim Establishment")
  end

  def start_text
    "Establish next claim"
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

  private

  def appeal_params
    { dispatched_to_station: establish_claim_params[:station_of_jurisdiction] }
  end

  def vacols_note_params
    params[:vacols_note]
  end

  def establish_claim_params
    params.require(:claim)
          .permit(:modifier, :end_product_code, :end_product_label, :end_product_modifier, :gulf_war_registry,
                  :suppress_acknowledgement_letter, :station_of_jurisdiction, :date)
  end
end
