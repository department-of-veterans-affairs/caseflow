class EstablishClaimsController < TasksController
  before_action :verify_assigned_to_current_user, only: [:show, :pdf, :cancel, :perform]
  before_action :verify_not_complete, only: [:perform]
  before_action :verify_manager_access, only: [:unprepared_tasks]

  def perform
    Task.transaction do
      task.appeal.update!(special_issues_params)
      Dispatch.new(claim: establish_claim_params, task: task).establish_claim!
    end
    render json: {}
  end

  def assign_existing_end_product
    Task.transaction do
      task.appeal.update!(special_issues_params)
      task.assign_existing_end_product!(params[:end_product_id])
    end
    render json: {}
  end

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

  def establish_claim_params
    params.require(:claim)
          .permit(:modifier, :end_product_code, :end_product_label, :end_product_modifier, :gulf_war_registry,
                  :suppress_acknowledgement_letter, :station_of_jurisdiction, :date)
  end

  def special_issues_params
    params.require(:special_issues).permit(:rice_compliance, :private_attorney, :waiver_of_overpayment,
                                           :pensions, :vamc, :incarcerated_veterans,
                                           :dic_death_or_accrued_benefits, :education_or_vocational_rehab,
                                           :foreign_claims, :manlincon_compliance,
                                           :hearings_travel_board_video_conference, :home_loan_guaranty,
                                           :insurance, :national_cemetery_administration, :spina_bifida,
                                           :radiation, :nonrating_issues, :proposed_incompetency,
                                           :manila_remand, :contaminated_water_at_camp_lejeune,
                                           :mustard_gas, :dependencies)
  end
end
