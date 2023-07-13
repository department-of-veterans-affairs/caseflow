# frozen_string_literal: true

# IssuesController for LegacyAppeals
class IssuesController < ApplicationController
  before_action :validate_access_to_task

  VACOLS_REPOSITORY_EXCEPTIONS = [
    Caseflow::Error::UserRepositoryError, Caseflow::Error::IssueRepositoryError
  ].freeze

  rescue_from ActiveRecord::RecordInvalid do |e|
    Rails.logger.error "IssuesController failed: #{e.message}"
    render json: { "errors": ["title": e.class.to_s, "detail": e.message] }, status: :bad_request
  end

  rescue_from(*VACOLS_REPOSITORY_EXCEPTIONS) do |e|
    handle_non_critical_error("issues", e)
  end

  def create
    return record_not_found unless appeal

    issue = Issue.create_in_vacols!(issue_attrs: create_params)

    # create MST/PACT task if issue was created
    if convert_to_bool(create_params[:mst_status]) ||
       convert_to_bool(create_params[:pact_status])
      issue_in_caseflow = appeal.issues.find { |i| i.vacols_sequence_id == issue.issseq.to_i }
      create_legacy_issue_update_task(issue_in_caseflow) if FeatureToggle.enabled?(:legacy_mst_pact_identification)
    end

    render json: { issues: json_issues }, status: :created
  end

  def update
    return record_not_found unless appeal

    issue = appeal.issues.find { |i| i.vacols_sequence_id == params[:vacols_sequence_id].to_i }
    if issue.mst_status != convert_to_bool(params[:issues][:mst_status]) ||
       issue.pact_status != convert_to_bool(params[:issues][:pact_status])
      create_legacy_issue_update_task(issue) if FeatureToggle.enabled?(:legacy_mst_pact_identification)
    end

    Issue.update_in_vacols!(
      vacols_id: appeal.vacols_id,
      vacols_sequence_id: params[:vacols_sequence_id],
      issue_attrs: issue_params
    )

    # Set LegacyAppeal issues to nil in order to refresh and retrieve new update
    appeal.issues = nil if appeal.is_legacy?

    render json: { issues: json_issues }, status: :ok
  end

  def destroy
    return record_not_found unless appeal

    Issue.delete_in_vacols!(
      vacols_id: appeal.vacols_id,
      vacols_sequence_id: params[:vacols_sequence_id]
    )
    render json: { issues: json_issues }, status: :ok
  end

  private

  def create_legacy_issue_update_task(issue)
    user = current_user

    # close out any tasks that might be open
    open_issue_task = Task.where(
      assigned_to: SpecialIssueEditTeam.singleton
    ).where(status: "assigned").where(appeal: appeal)
    open_issue_task[0].delete unless open_issue_task.empty?

    task = IssuesUpdateTask.create!(
      appeal: appeal,
      parent: appeal.root_task,
      assigned_to: SpecialIssueEditTeam.singleton,
      assigned_by: user,
      completed_by: user
    )

    # set up data for added or edited issue depending on the params action
    disposition = issue.readable_disposition.nil? ? "N/A" : issue.readable_disposition
    change_category = (params[:action] == "create") ? "Added Issue" : "Edited Issue"
    updated_mst_status = convert_to_bool(params[:issues][:mst_status]) unless params[:action] == "create"
    updated_pact_status = convert_to_bool(params[:issues][:pact_status]) unless params[:action] == "create"

    note = params[:issues][:note].nil? ? "N/A" : params[:issues][:note]
    # use codes from params to get descriptions
    # opting to use params vs issue model to capture in-flight issue changes
    program_code = params[:issues][:program]
    issue_code = params[:issues][:issue]
    level_1_code = params[:issues][:level_1]

    # line up param codes to their descriptions
    param_issue = Constants::ISSUE_INFO[program_code]
    iss = param_issue["levels"][issue_code]["description"] unless issue_code.nil?
    level_1_description = level_1_code.nil? ? "N/A" : param_issue["levels"][issue_code]["levels"][level_1_code]["description"]

    # format the task instructions and close out
    task.format_instructions(
      change_category,
      [
        "Benefit Type: #{param_issue['description']}\n",
        "Issue: #{iss}\n",
        "Code: #{[level_1_code, level_1_description].join(" - ")}\n",
        "Note: #{note}\n",
        "Disposition: #{disposition}\n"
      ].compact.join("\r\n"),
      "",
      issue.mst_status,
      issue.pact_status,
      updated_mst_status,
      updated_pact_status
    )
    task.completed!
    # create SpecialIssueChange record to log the changes
    SpecialIssueChange.create!(
      issue_id: issue.id,
      appeal_id: appeal.id,
      appeal_type: "LegacyAppeal",
      task_id: task.id,
      created_at: Time.zone.now.utc,
      created_by_id: user.id,
      created_by_css_id: user.css_id,
      original_mst_status: issue.mst_status,
      original_pact_status: issue.pact_status,
      updated_mst_status: updated_mst_status,
      updated_pact_status: updated_pact_status,
      change_category: change_category
    )
  end

  def convert_to_bool(status)
    status == "Y"
  end

  def json_issues
    appeal.issues.map do |issue|
      ::WorkQueue::LegacyIssueSerializer.new(issue).serializable_hash[:data][:attributes]
    end
  end

  def validate_access_to_task
    current_user.fail_if_no_access_to_legacy_task!(appeal.vacols_id)
  end

  def appeal
    @appeal ||= Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def issue_params
    safe_params = params.require("issues")
      .permit(:note,
              :program,
              :issue,
              :level_1,
              :level_2,
              :level_3,
              :mst_status,
              :pact_status).to_h
    safe_params[:vacols_user_id] = current_user.vacols_uniq_id
    safe_params
  end

  def create_params
    issue_params.merge(vacols_id: appeal.vacols_id)
  end

  def record_not_found
    render json: {
      "errors": [
        "title": "Record Not Found",
        "detail": "Record with that ID is not found"
      ]
    }, status: :not_found
  end
end
