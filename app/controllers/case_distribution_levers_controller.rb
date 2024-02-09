# frozen_string_literal: true

class CaseDistributionLeversController < ApplicationController
  before_action :verify_access
  before_action :authorize_admin, only: [:update_levers]

  def acd_lever_index
    # acd_levers_for_store should replace the acd_levers value
    # once the lever list has been cleaned up and removed from the
    # current frontend workflow.
    @acd_levers = CaseDistributionLever.all
    @acd_levers_for_store = grouped_levers
    @acd_history = CaseDistributionAuditLeverEntry.lever_history
    @user_is_an_acd_admin = CDAControlGroup.singleton.user_is_admin?(current_user)

    render "index"
  end

  def levers
    render json: { levers: grouped_levers, lever_history: CaseDistributionAuditLeverEntry.lever_history }
  end

  def update_levers
    errors = CaseDistributionLever.update_acd_levers(allowed_params[:current_levers], current_user)

    render json: {
      errors: errors,
      lever_history: CaseDistributionAuditLeverEntry.lever_history,
      levers: grouped_levers
    }
  end

  private

  def authorize_admin
    error = ["UNAUTHORIZED"]

    resp = {
      status_code: 500,
      message: error,
      user_is_an_acd_admin: false,
      lever_history: CaseDistributionAuditLeverEntry.lever_history,
      levers: grouped_levers
    }
    render json: resp unless CDAControlGroup.singleton.user_is_admin?(current_user)
  end

  def allowed_params
    params.permit(current_levers: [:id, :value])
  end

  def verify_access
    return true if current_user&.organizations && current_user.organizations.any?(&:users_can_view_levers?)

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  def grouped_levers
    CaseDistributionLever.all.group_by(&:lever_group)
  end
end
