class Dispatch::UserQuotasController < ApplicationController
  before_action :verify_manager_access

  def update
    user_quota.update!(user_quota_params)

    # Changing the user quota affects all other quotas for the team.
    # So return all of them and not just the one changed
    render json: user_quota.team_quota.user_quotas.map(&:to_hash)
  end

  private

  def user_quota_params
    { locked_task_count: params[:locked_task_count] }
  end

  def user_quota
    UserQuota.find(params[:id])
  end

  def verify_manager_access
    # Keep it simple because Claim Establishment is the only type of
    # task with quotas currently, add more user functions here as neccessary
    verify_authorized_roles("Manage Claim Establishment")
  end
end
