# frozen_string_literal: true

class CavcDashboardController < ApplicationController
  before_action :react_routed, :verify_access, except: [:cavc_decision_reasons, :cavc_selection_bases, :update_data, :save]

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
    render json: { successful: true }
  end

  # add data to render: json as a key-value pair that matchecs the front-end state key
  def render_index_data_as_json(cavc_dashboards)
    render json: {
      cavc_dashboards: cavc_dashboards
    }
  end

  def save
    dashboards = params[:cavc_dashboards].as_json
    checked_boxes = params[:checked_boxes]

    dashboards.each do |dash|
      dashboard_id = dash["id"]
      submitted_issues = dash["cavc_dashboard_issues"]
      submitted_dispositions = dash["cavc_dashboard_dispositions"]
      new_issue_set = create_or_update_dashboard_issues(submitted_issues, submitted_dispositions)
      # deleting removed issues cascades to their dispositions so deleting the dispositions manually isn't required
      delete_removed_dashboard_issues(dashboard_id, new_issue_set)
      create_or_update_dashboard_dispositions(submitted_dispositions)
    end

    new_disp_to_reason_set = create_new_dispositions_to_reasons(checked_boxes)

    delete_removed_dispositions_to_reasons(new_disp_to_reason_set)

    render json: { successful: true }
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

  private

  # rubocop:disable Metrics/MethodLength
  def create_or_update_dashboard_issues(submitted_issues, submitted_dispositions)
    submitted_issues.map do |issue|
      # this regex is how the front-end assigns a temporary ID value to a new issue
      if issue["id"].to_s.match?(/\d-\d/)
        new_issue = CavcDashboardIssue.create!(benefit_type: issue["benefit_type"],
                                               cavc_dashboard_id: issue["cavc_dashboard_id"],
                                               issue_category: issue["issue_category"])
        CavcDashboardDisposition.create!(cavc_dashboard_id: issue["cavc_dashboard_id"],
                                         cavc_dashboard_issue_id: new_issue.id)

        # set relevant ID values in the submitted data to the new issue's ID value
        submitted_dispositions
          .filter { |disp| disp["cavc_dashboard_issue_id"] == issue["id"] }
          .first["cavc_dashboard_issue_id"] = new_issue.id
        issue["id"] = new_issue.id
        new_issue
      else
        existing_issue = CavcDashboardIssue.find_by(id: issue["id"])
        unless existing_issue.benefit_type == issue["benefit_type"] &&
               existing_issue.issue_category == issue["issue_category"]
          existing_issue.update!(benefit_type: issue["benefit_type"],
                                 issue_category: issue["issue_category"])
        end
        existing_issue
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def delete_removed_dashboard_issues(dashboard_id, new_issue_set)
    dashboard = CavcDashboard.find_by(id: dashboard_id)
    all_dashboard_issues = dashboard.cavc_dashboard_issues
    issues_to_delete = all_dashboard_issues - new_issue_set
    issues_to_delete.map(&:destroy)
  end

  def create_or_update_dashboard_dispositions(submitted_dispositions)
    submitted_dispositions.each do |disp|
      cdd = if disp["request_issue_id"]
              CavcDashboardDisposition.find_by(request_issue_id: disp["request_issue_id"])
            else
              CavcDashboardDisposition.find_or_create_by(cavc_dashboard_issue_id: disp["cavc_dashboard_issue_id"])
            end
      cdd.update!(disposition: disp["disposition"]) unless disp["disposition"] == cdd.disposition
    end
  end

  def delete_removed_dispositions_to_reasons(new_disp_to_reason_set)
    cdd_ids = new_disp_to_reason_set.map(&:cavc_dashboard_disposition_id).uniq
    all_dispositions_to_reasons = cdd_ids
      .map { |id| CavcDashboardDisposition.find_by(id: id) }
      .flat_map(&:cavc_dispositions_to_reasons)

    reasons_to_delete = all_dispositions_to_reasons - new_disp_to_reason_set
    reasons_to_delete.map(&:destroy)
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def create_new_dispositions_to_reasons(checked_boxes)
    # checked_box format from cavcDashboardActions.js:
    # [issue_id, issue_type, decision_reason_id, basis_for_selection_category, basis_for_selection]
    # basis_for_selection: { checkboxId, value, label, otherText }
    checked_boxes.map do |box|
      cdd = if box[1] == "request_issue"
              CavcDashboardDisposition.find_by(request_issue_id: box[0])
            else
              CavcDashboardDisposition.find_by(cavc_dashboard_issue_id: box[0])
            end

      basis = if box[4] && box[4]["otherText"]
                CavcSelectionBasis.find_or_create_by(
                  basis_for_selection: box[4]["otherText"],
                  category: box[3]
                )
              elsif box[4] && box[4]["value"]
                CavcSelectionBasis.find_by(id: box[4]["value"].to_i)
              end

      cdtr = CavcDispositionsToReason.find_or_create_by(cavc_dashboard_disposition: cdd,
                                                        cavc_decision_reason_id: box[2])
      cdtr.update!(cavc_selection_basis_id: basis.id) if basis&.id
      cdtr
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
