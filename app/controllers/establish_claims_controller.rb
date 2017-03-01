class EstablishClaimsController < TasksController
  before_action :verify_assigned_to_current_user, only: [:show, :pdf, :cancel, :perform]
  before_action :verify_not_complete, only: [:perform]
  before_action :verify_manager_access, only: [:unprepared_tasks, :update_employee_count]

  def perform
    # If we've already created the EP, we want to send the user to the note page
    return render json: { require_note: true } if task.reviewed?

    Task.transaction do
      task.appeal.update!(appeal_params)
      Dispatch.new(claim: establish_claim_params, task: task).establish_claim!
      task.complete!(status: 0) unless task.appeal.special_issues?
    end
    render json: { require_note: task.appeal.special_issues? }
  end

  def note_complete
    task.complete!(status: 0)
    render json: {}
  end

  def email_complete
    task.complete!(status: Task.completion_status_code(:special_issue_emailed))
    render json: {}
  end

  def no_email_complete
    task.complete!(status: Task.completion_status_code(:special_issue_not_emailed))
    render json: {}
  end

  def assign_existing_end_product
    Dispatch.new(task: task)
            .assign_existing_end_product!(end_product_id: params[:end_product_id],
                                          special_issues: special_issues_params)
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
    "Establish Next Claim"
  end

  def logo_name
    "Dispatch"
  end

  def logo_path
    establish_claims_path
  end

  private

  def appeal_params
    special_issues_params.merge(dispatched_to_station: establish_claim_params[:station_of_jurisdiction])
  end

  def establish_claim_params
    params.require(:claim)
          .permit(:modifier, :end_product_code, :end_product_label, :end_product_modifier, :gulf_war_registry,
                  :suppress_acknowledgement_letter, :station_of_jurisdiction, :date)
  end

  def special_issues_params
    params.require(:special_issues).permit(:contaminated_water_at_camp_lejeune,
                                           :dic_death_or_accrued_benefits_united_states,
                                           :education_gi_bill_dependents_educational_assistance_scholars,
                                           :foreign_claim_compensation_claims_dual_claims_appeals,
                                           :foreign_pension_dic_all_other_foreign_countries,
                                           :foreign_pension_dic_mexico_central_and_south_american_caribb,
                                           :hearing_including_travel_board_video_conference,
                                           :home_loan_guarantee, :incarcerated_veterans, :insurance,
                                           :manlincon_compliance, :mustard_gas, :national_cemetery_administration,
                                           :nonrating_issue, :pension_united_states, :private_attorney_or_agent,
                                           :radiation, :rice_compliance, :spina_bifida,
                                           :us_territory_claim_american_samoa_guam_northern_mariana_isla,
                                           :us_territory_claim_philippines,
                                           :us_territory_claim_puerto_rico_and_virgin_islands,
                                           :vamc, :vocational_rehab, :waiver_of_overpayment)
  end
end
