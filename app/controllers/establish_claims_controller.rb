class EstablishClaimsController < TasksController
  before_action :verify_assigned_to_current_user, only: [:show, :pdf, :cancel, :perform]
  before_action :verify_not_complete, only: [:perform]
  before_action :verify_manager_access, only: [:unprepared_tasks, :update_employee_count]
  before_action :set_application

  def perform
    # If we've already created the EP, no-op and send the user to the note page
    task.perform!(establish_claim_params) unless task.reviewed?
    render json: {}

  rescue EstablishClaim::EndProductAlreadyExistsError
    render json: { error_code: "duplicate_ep" }, status: 422
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
    Rails.cache.write("employee_count", params[:count], expires_in: nil)
    render json: {}
  end

  def cancel
    Task.transaction do
      task.appeal.update!(special_issues_params) if params[:special_issues]
      task.cancel!(cancel_feedback)
    end

    render json: {}
  end

  # Index of all tasks that are unprepared
  def unprepared_tasks
    @unprepared_tasks ||= EstablishClaim.unprepared.oldest_first
  end

  private

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

  # sets a task completion status and updates the claim establishment
  # for a task if it exists.
  def handle_task_status_update(completion_status_code)
    task.complete!(status: completion_status_code)
    task.claim_stablishment.update!(decision_date: Time.zone.now) if task.claim_establishment
    render json: {}
  end

  def appeal_params
    { dispatched_to_station: establish_claim_params[:station_of_jurisdiction] }
  end

  def review_complete_params
    { vacols_note: params[:vacols_note] }
  end

  def email_params
    { email_ro_id: params[:email_ro_id], email_recipient: params[:email_recipient] }
  end

  def establish_claim_params
    params.require(:claim)
          .permit(:modifier, :end_product_code, :end_product_label, :end_product_modifier, :gulf_war_registry,
                  :suppress_acknowledgement_letter, :station_of_jurisdiction, :date)
  end
end
