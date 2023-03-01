# frozen_string_literal: true

class CavcDashboardController < ApplicationController
  before_action :react_routed, :verify_access, except: [:cavc_decision_reasons, :cavc_selection_bases, :update_data]

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    respond_to do |format|
      format.html { render template: "queue/index" }
      # dashboard specific data required on load should be loaded through this method
      format.json do
        # get cavc_remand by URL provided appeal_id; id can be for source or remand appeal so try both
        cavc_remand =
          CavcRemand.find_by(remand_appeal_id: Appeal.find_by(uuid: params[:appeal_id]).id) ||
          CavcRemand.find_by(source_appeal_id: Appeal.find_by(uuid: params[:appeal_id]).id)

        # get all remands where source or remand appeal id correlates to above remand
        # if check is required or cavc_remands will find unrelated remands where remand_appeal is nil
        if cavc_remand
          cavc_remands =
            CavcRemand.where(remand_appeal: cavc_remand.remand_appeal)
              .or(CavcRemand.where(source_appeal: cavc_remand.source_appeal))
              .order(:cavc_docket_number)

          serialized_dashboards = cavc_remands&.map do |remand|
            dashboard = CavcDashboard.find_or_create_by(cavc_remand: remand)
            WorkQueue::CavcDashboardSerializer.new(dashboard).serializable_hash[:data][:attributes]
          end
        end

        render_index_data_as_json(serialized_dashboards)
      end
    end
  end

  def update_data
    updated_data = params[:updatedData].as_json

    dashboard = CavcDashboard.find_by(id: updated_data["id"])
    dashboard.update!(
      board_decision_date: updated_data["boardDecisionDateUpdate"],
      board_docket_number: updated_data["boardDocketNumberUpdate"],
      cavc_decision_date: updated_data["cavcDecisionDateUpdate"],
      cavc_docket_number: updated_data["cavcDocketNumberUpdate"],
      joint_motion_for_remand: updated_data["jointMotionForRemandUpdate"]
    )
  end

  # add data to render: json as a key-value pair that matchecs the front-end state key
  def render_index_data_as_json(cavc_dashboards)
    render json: {
      cavc_dashboards: cavc_dashboards
    }
  end

  def cavc_decision_reasons
    render json: CavcDecisionReason.all
  end

  def cavc_selection_bases
    render json: CavcSelectionBasis.all
  end

  def verify_access
    if !(OaiTeam.singleton.users.include?(current_user) || OccTeam.singleton.users.include?(current_user)) ||
       !Appeal::UUID_REGEX.match?(params[:appeal_id])
      redirect_to "/queue/appeals/#{params[:appeal_id]}"
    end
  end
end
