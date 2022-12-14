# frozen_string_literal: true

class SpecialIssuesController < ApplicationController
  before_action :validate_access_to_appeal

  rescue_from Caseflow::Error::UserRepositoryError do
    redirect_to "/unauthorized"
  end

  def create
    return record_not_found unless appeal

    if appeal.special_issue_list
      appeal.special_issue_list.update(special_issue_params)
    else
      appeal.special_issue_list = SpecialIssueList.create(special_issue_params, appeal: appeal)
    end

    render json: appeal.special_issue_list.as_json
  end

  def index
    return record_not_found unless appeal

    appeal.special_issue_list = SpecialIssueList.create(appeal: appeal) if !appeal.special_issue_list

    render json: appeal.special_issue_list.as_json
  end

  def appeal
    @appeal ||= Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def validate_access_to_appeal
    current_user.appeal_has_task_assigned_to_user?(appeal)
  end

  def special_issue_params
    params.require("special_issues")
      .permit(:rice_compliance, :private_attorney_or_agent,
              :waiver_of_overpayment, :pension_united_states, :vamc, :incarcerated_veterans,
              :dic_death_or_accrued_benefits_united_states, :vocational_rehab,
              :foreign_claim_compensation_claims_dual_claims_appeals, :manlincon_compliance,
              :hearing_including_travel_board_video_conference, :home_loan_guaranty, :insurance,
              :national_cemetery_administration, :spina_bifida, :radiation, :nonrating_issue,
              :us_territory_claim_philippines, :contaminated_water_at_camp_lejeune, :mustard_gas,
              :education_gi_bill_dependents_educational_assistance_scholars,
              :foreign_pension_dic_all_other_foreign_countries,
              :foreign_pension_dic_mexico_central_and_south_america_caribb,
              :us_territory_claim_american_samoa_guam_northern_mariana_isla,
              :us_territory_claim_puerto_rico_and_virgin_islands,
              :burn_pit, :military_sexual_trauma, :blue_water,
              :no_special_issues)
  end

  def record_not_found
    render json: {
      "errors": [
        "title": "Record Not Found",
        "detail": "Record with that ID is not found"
      ]
    }, status: :not_found
  end
end
