class CaseDistributionLeversController < ApplicationController
  before_action :verify_access

  def acd_lever_index
    @acd_levers = CaseDistributionLever.all
    @acd_history = CaseDistributionAuditLeverEntry.past_year
    cda_group_organization = Organization.where(name: "Case Distribution Algorithm Control Group").first
    @user_is_an_acd_admin = cda_group_organization && cda_group_organization.user_is_admin?(current_user)

    render "index"
  end

  def update_levers_and_history
    cda_group_organization = Organization.where(name: "Case Distribution Algorithm Control Group").first
    if cda_group_organization && cda_group_organization.user_is_admin?(current_user)
      errors = update_acd_levers(JSON.parse(params["current_levers"]))

      if errors.empty?
        errors = add_audit_lever_entries(JSON.parse(params["audit_lever_entries"]))
      end

      if errors.empty?
        render json: { errors: [], successful: true }
      else
        render json: { errors: errors, successful: false }
      end
    else
      redirect_to "/unauthorized"
    end
  end

  def update_acd_levers(current_levers)
    grouped_levers = current_levers.index_by { |lever| lever["id"] }

    ActiveRecord::Base.transaction do
      @levers = CaseDistributionLever.update(grouped_levers.keys, grouped_levers.values)
      if @levers.all? { |lever| lever.changed? }
        return []
      else
        return @levers.select(&:invalid?).map{ |l| "Lever ID:#{l.id} - #{l.errors.full_messages}" }.join("<br/>")
      end
    end
  end

  def add_audit_lever_entries(audit_lever_entries)
    begin
      ActiveRecord::Base.transaction do
        CaseDistributionAuditLeverEntry.create(audit_lever_entries)
      end
    rescue Exception => error
      return [error]
    end

    return []
  end

  private
  def verify_access
    return true if current_user&.organizations && current_user&.organizations&.any?(&:users_can_view_levers?)

    Rails.logger.debug("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end
end
