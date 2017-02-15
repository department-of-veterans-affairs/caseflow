class EstablishClaimsController < TasksController
  before_action :verify_assigned_to_current_user, only: [:show, :pdf, :cancel, :perform]
  before_action :verify_not_complete, only: [:perform]
  before_action :verify_manager_access, only: [:unprepared_tasks]

  def perform
    task.appeal.update!(special_issues_params)
    Dispatch.new(claim: establish_claim_params, task: task).establish_claim!
    render json: {}
  end

  def assign_existing_end_product
    task.assign_existing_end_product!(params[:end_product_id])
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
    params.require(:specialIssues).permit(:contaminated_water_at_camp_lejeune,
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
