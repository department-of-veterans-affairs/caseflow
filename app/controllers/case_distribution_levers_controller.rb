# frozen_string_literal: true

class CaseDistributionLeversController < ApplicationController
  before_action :verify_access

  def acd_lever_index
    # acd_levers_for_store should replace the acd_levers value
    # once the lever list has been cleaned up and removed from the
    # current frontend workflow.
    @acd_levers = CaseDistributionLever.all
    @acd_levers_for_store = CaseDistributionLever.all.group_by(&:lever_group)
    history = CaseDistributionAuditLeverEntry.includes(:user, :case_distribution_lever).past_year
    @acd_history = CaseDistributionAuditLeverEntrySerializer.new(history)
      .serializable_hash[:data].map{ |entry| entry[:attributes] }
    @user_is_an_acd_admin = CDAControlGroup.singleton.user_is_admin?(current_user)

    render "index"
  end

  def update_levers_and_history
    redirect_to "/unauthorized" unless CDAControlGroup.singleton.user_is_admin?(current_user)

    puts params.class
    puts params
    puts allowed_params.class
    puts allowed_params.keys
    puts allowed_params
    puts allowed_params[:current_levers].class
    puts allowed_params[:current_levers]

    errors = CaseDistributionLever.update_acd_levers(allowed_params[:current_levers])

    render json: { errors: errors, successful: false }
  end

  private

  def allowed_params
    params.permit(current_levers: [])
  end

  def verify_access
    return true if current_user&.organizations && current_user.organizations.any?(&:users_can_view_levers?)

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end
end
