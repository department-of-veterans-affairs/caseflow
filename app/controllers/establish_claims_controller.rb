class EstablishClaimsController < TasksController
  before_action :verify_assigned_to_current_user, only: [:show, :pdf, :cancel, :perform]
  before_action :verify_not_complete, only: [:perform]

  def perform
    task.appeal.update_attributes(special_issues_params)
    Dispatch.new(claim: establish_claim_params, task: task).establish_claim!
    render json: {}
  end

  def assign_existing_end_product
    task.assign_existing_end_product!(params[:end_product_id])
    render json: {}
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
                  :suppress_acknowledgement_letter, :station_of_jurisdiction, :date,
                  special_issues: [:rice_compliance, :private_attorney, :waiver_of_overpayment,
                                   :pensions, :vamc, :incarcerated_veterans,
                                   :dic_death_or_accrued_benefits, :education_or_vocational_rehab,
                                   :foreign_claims, :manlincon_compliance,
                                   :hearings_travel_board_video_conference, :home_loan_guaranty,
                                   :insurance, :national_cemetery_administration, :spina_bifida,
                                   :radiation, :nonrating_issues, :proposed_incompetency,
                                   :manila_remand, :contaminated_water_at_camp_lejeune,
                                   :mustard_gas, :dependencies])
  end

  def special_issues_params
    params.require(:specialIssues).permit(:rice_compliance, :private_attorney, :waiver_of_overpayment,
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
