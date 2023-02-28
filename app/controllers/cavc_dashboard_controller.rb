# frozen_string_literal: true

class CavcDashboardController < ApplicationController
  before_action :react_routed, :verify_access, except: [:cavc_decision_reasons, :cavc_selection_bases, :save]

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
      submitted_issues = dash["cavc_dashboard_issues"]
      submitted_dispositions = dash["cavc_dashboard_dispositions"]

      create_or_update_dashboard_issues(submitted_issues, submitted_dispositions)
      create_or_update_dashboard_dispositions(submitted_dispositions)
    end

    create_new_dispositions_to_reasons(checked_boxes)

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

  def create_or_update_dashboard_issues(submitted_issues, submitted_dispositions)
    submitted_issues.each do |issue|
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
      else
        existing_issue = CavcDashboardIssue.find_by(id: issue["id"])
        unless existing_issue.benefit_type == issue["benefit_type"] &&
               existing_issue.issue_category == issue["issue_category"]
          existing_issue.update!(benefit_type: issue["benefit_type"],
                                 issue_category: issue["issue_category"])
        end
      end
    end
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

  def create_new_dispositions_to_reasons(checked_boxes)
    # checked_box format from cavcDashboardActions.js: [issue_id, issue_type, decision_reason_id]
    checked_boxes.each do |box|
      cdd = if box[1] == "request_issue"
              CavcDashboardDisposition.find_by(request_issue_id: box[0])
            else
              CavcDashboardDisposition.find_by(cavc_dashboard_issue_id: box[0])
            end

      CavcDispositionsToReason.find_or_create_by(cavc_dashboard_disposition: cdd, cavc_decision_reason_id: box[2])
    end
  end
end
