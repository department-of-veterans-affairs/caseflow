class CaseDistributionLeversController < ApplicationController
  before_action :verify_access

  def acd_lever_index
    @acd_levers = CaseDistributionLever.all.to_json
    @acd_history = CaseDistributionAuditLeverEntry.past_year.to_json
    @user_is_an_acd_admin = current_user.admin?
    # binding.pry

    render "index" ##TODO: path to file
  end

  def update_levers_and_history
    errors = nil
    if user_is_an_acd_admin?
      errors = update_acd_levers
      errors  = add_audit_lever_entries

      if errors.empty?
        render json: { successful: true }
      else
        render json: { errors: errors, successful: false }
      end

    else
      redirect_to "/unauthorized"
    end
  end

  def update_levers
    ActiveRecord::Base.transaction do
      CaseDistributionLever.update_levers(params[current_levers])
    end
    # rescue ActiveRecord::RecordInvalid => error
    #   return error
    # end
  end

  def add_audit_lever_entries
    ActiveRecord::Base.transaction do
      CaseDistributionAuditLeverEntries.create_entries(params[audit_lever_entries])
    end
    # rescue ActiveRecord::RecordInvalid => error
    #   raise error
    # end
  end

  private
  def verify_access
    return true if current_user.admin?
    return true if current_user.can?("View Levers")

    Rails.logger.debug("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end
end
