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
      task.update_claim_establishment!(ep_code: establish_claim_params[:end_product_code])
      Dispatch.new(claim: establish_claim_params, task: task).establish_claim!
    end
    render json: {}

  rescue Dispatch::EndProductAlreadyExistsError
    render json: { error_code: "duplicate_ep" }, status: 422
  end

  # This POST updates VACOLS & VBMS Note
  def review_complete
    Task.transaction do
      Dispatch.new(task: task, vacols_note: vacols_note_params).update_vacols!
      task.complete!(status: 0)
      task.update_claim_establishment!
    end
    render json: {}
  end

  def email_complete
    task.complete!(status: Task.completion_status_code(:special_issue_emailed))
    task.update_claim_establishment!(
      email_recipient: email_params[:email_recipient],
      email_ro_id: email_params[:email_ro_id]
    )

    render json: {}
  end

  # Because there are no unhandled email addresses this code path is never run
  # We will remove this soon.
  # :nocov:
  def no_email_complete
    Task.transaction do
      task.complete!(status: Task.completion_status_code(:special_issue_not_emailed))
      task.update_claim_establishment!
    end

    render json: {}
  end
  # :nocov:

  def assign_existing_end_product
    Task.transaction do
      Dispatch.new(task: task)
              .assign_existing_end_product!(end_product_id: params[:end_product_id],
                                            special_issues: special_issues_params)
      task.update_claim_establishment!
    end

    render json: {}
  end

  def update_employee_count
    Rails.cache.write("employee_count", params[:count], expires_in: nil)
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

  # sets a task completion status and updates the claim establishment
  # for a task if it exists.
  def handle_task_status_update(completion_status_code)
    task.complete!(status: Task.completion_status_code(completion_status_code))
    task.claim_stablishment.update!(decision_date: Time.zone.now) if task.claim_establishment
    render json: {}
  end

  def appeal_params
    { dispatched_to_station: establish_claim_params[:station_of_jurisdiction] }
  end

  def vacols_note_params
    params[:vacols_note]
  end

  def email_params
    params.permit(:email_ro_id, :email_recipient)
  end

  def establish_claim_params
    params.require(:claim)
          .permit(:modifier, :end_product_code, :end_product_label, :end_product_modifier, :gulf_war_registry,
                  :suppress_acknowledgement_letter, :station_of_jurisdiction, :date)
  end
end
