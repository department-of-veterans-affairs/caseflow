# frozen_string_literal: true

class CavcDashboardController < ApplicationController
  before_action :react_routed, :verify_access, except: :cavc_decision_reasons

  def set_application
    RequestStore.store[:application] = "queue"
  end

  # def index
  #   respond_to do |format|
  #     format.html { render template: "queue/index" }
  #     # add format.json later to allow GET requests from ApiUtil to get information
  #   end
  # end

  def cavc_decision_reasons
    render json: CavcDecisionReason.all
  end

  def verify_access
    redirect_to "/queue/appeals/#{params[:appeal_id]}" unless Appeal::UUID_REGEX.match?(params[:appeal_id])

    # uncomment this section once the organizations are added
    #
    # if !current_user.organizations.include?(Organization.find_by_name_or_url("Office of Assessment and Improvement") ||
    #   Organization.find_by_name_or_url("Office of Chief Counsel"))
    #   session["return_to"] = request.original_url
    #   redirect_to "/queue/appeals/#{params[:appeal_id]}"
    # end
  end
end
