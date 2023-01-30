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
        cavc_remand =
          CavcRemand.find_by(remand_appeal_id: Appeal.find_by(uuid: params[:appeal_id]).id) ||
          CavcRemand.find_by(source_appeal_id: Appeal.find_by(uuid: params[:appeal_id]).id)
        cavc_remands =
          CavcRemand.where(remand_appeal_id: cavc_remand.remand_appeal.id)
            .or(CavcRemand.where(source_appeal_id: cavc_remand.source_appeal.id))
            .order(:cavc_docket_number)

        render_index_data_as_json(cavc_remands)
      end
    end
  end

  # add data to render: json as a key-value pair that matchecs the front-end state key
  def render_index_data_as_json(cavc_remands)
    render json: {
      cavc_remands: cavc_remands
    }
  end

  def cavc_decision_reasons
    render json: CavcDecisionReason.all
  end

  def cavc_selection_bases
    render json: CavcSelectionBasis.all
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
