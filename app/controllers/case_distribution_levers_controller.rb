# frozen_string_literal: true

class CaseDistributionLeversController < ApplicationController
  before_action :verify_access

  def acd_lever_index
    # acd_levers_for_store should replace the acd_levers value
    # once the lever list has been cleaned up and removed from the
    # current frontend workflow.
    @acd_levers = CaseDistributionLever.all
    @acd_levers_for_store = grouped_levers
    @acd_history = lever_history
    @user_is_an_acd_admin = CDAControlGroup.singleton.user_is_admin?(current_user)

    render "index"
  end

  def update_levers
    redirect_to "/unauthorized" unless CDAControlGroup.singleton.user_is_admin?(current_user)

    errors = CaseDistributionLever.update_acd_levers(allowed_params[:current_levers], current_user)

    render json: {
      errors: errors,
      successful: errors.empty?,
      lever_history: lever_history,
      levers: grouped_levers
    }
  end

  private

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

  def lever_history
    history = CaseDistributionAuditLeverEntry.includes(:user, :case_distribution_lever).past_year
    CaseDistributionAuditLeverEntrySerializer.new(history).serializable_hash[:data].map{ |entry| entry[:attributes] }
  end
end
