# frozen_string_literal: true

class CavcDashboardController < ApplicationController
  before_action :react_routed, :verify_access, except: [:cavc_decision_reasons, :cavc_selection_bases]

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    respond_to do |format|
      format.html { render template: "queue/index" }
      # dashboard specific data required on load should be loaded through this method
      format.json do
        cavc_remand = CavcRemand.find_by(remand_appeal_id: Appeal.find_by(uuid: params[:appeal_id]).id)
        dashboard_dispositions = CavcDashboardDisposition.where(cavc_remand_id: cavc_remand.id)

        render_index_data_as_json(dashboard_dispositions)
      end
    end
  end

  # add data to render: json as a key-value pair that matchecs the front-end state key
  def render_index_data_as_json(dashboard_dispositions)
    render json: {
      dashboard_dispositions: dashboard_dispositions
    }
  end

  def cavc_decision_reasons
    render json: CavcDecisionReason.all
  end

  def cavc_selection_bases
    render json: CavcSelectionBasis.all
  end

  def verify_access
    if !(OicTeam.singleton.users.include?(user) ||
      Occ.singleton.users.include?(user))
      session["return_to"] = request.original_url
    end
    else
    redirect_to "/queue/appeals/#{params[:appeal_id]}" unless Appeal::UUID_REGEX.match?(params[:appeal_id])
    end
  end
end
