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

    Issue.create_in_vacols!(issue_attrs: create_params)

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

  def create_legacy_issue_update_task(before_issue)
    user = current_user
    task = IssuesUpdateTask.create!(
      appeal: appeal,
      parent: appeal.root_task,
      assigned_to: SpecialIssueEditTeam.singleton,
      assigned_by: user,
      completed_by: user
    )
    # format the task instructions and close out
    task.format_instructions(
      "Edited Issue",
      [
        "Benefit Type: #{before_issue.labels[0]}\n",
        "Issue: #{before_issue.labels[1..-2].join("\n")}\n",
        "Code: #{[before_issue.codes[-1], before_issue.labels[-1]].join(" - ")}\n",
        "Note: #{before_issue.note}\n",
        "Disposition: #{before_issue.readable_disposition}\n"
      ].compact.join("\r\n"),
      "",
      before_issue.mst_status,
      before_issue.pact_status,
      convert_to_bool(params[:issues][:mst_status]),
      convert_to_bool(params[:issues][:pact_status])
    )
    task.completed!
    # create SpecialIssueChange record to log the changes
    SpecialIssueChange.create!(
      issue_id: before_issue.id,
      appeal_id: appeal.id,
      appeal_type: "LegacyAppeal",
      task_id: task.id,
      created_at: Time.zone.now.utc,
      created_by_id: user.id,
      created_by_css_id: user.css_id,
      original_mst_status: before_issue.mst_status,
      original_pact_status: before_issue.pact_status,
      updated_mst_status: convert_to_bool(params[:issues][:mst_status]),
      updated_pact_status: convert_to_bool(params[:issues][:pact_status]),
      change_category: "Edited Issue"
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
