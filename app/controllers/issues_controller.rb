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
      issue_in_caseflow = appeal.issues.find { |iss| iss.vacols_sequence_id == issue.issseq.to_i }
      create_legacy_issue_update_task(issue_in_caseflow) if FeatureToggle.enabled?(
        :legacy_mst_pact_identification, user: RequestStore[:current_user]
      )
    end

    render json: { issues: json_issues }, status: :created
  end

  # rubocop:disable Metrics/AbcSize
  def update
    return record_not_found unless appeal

    issue = appeal.issues.find { |iss| iss.vacols_sequence_id == params[:vacols_sequence_id].to_i }
    if issue.mst_status != convert_to_bool(params[:issues][:mst_status]) ||
       issue.pact_status != convert_to_bool(params[:issues][:pact_status])
      create_legacy_issue_update_task(issue) if FeatureToggle.enabled?(
        :legacy_mst_pact_identification, user: RequestStore[:current_user]
      )
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
  # rubocop:enable Metrics/AbcSize

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
    # close out any tasks that might be open
    open_issue_task = Task.where(
      assigned_to: SpecialIssueEditTeam.singleton
    ).where(status: "assigned").where(appeal: appeal)
    open_issue_task[0].delete unless open_issue_task.empty?

    task = IssuesUpdateTask.create!(
      appeal: appeal,
      parent: appeal.root_task,
      assigned_to: SpecialIssueEditTeam.singleton,
      assigned_by: current_user,
      completed_by: current_user
    )
    task_instructions_helper(issue, task)
  end

  # rubocop:disable Metrics/MethodLength
  def task_instructions_helper(issue, task)
    # set up data for added or edited issue depending on the params action
    change_category = (params[:action] == "create") ? "Added Issue" : "Edited Issue"
    updated_mst_status = convert_to_bool(params[:issues][:mst_status]) unless params[:action] == "create"
    updated_pact_status = convert_to_bool(params[:issues][:pact_status]) unless params[:action] == "create"
    instruction_params = {
      issue: issue,
      task: task,
      updated_mst_status: updated_mst_status,
      updated_pact_status: updated_pact_status,
      change_category: change_category
    }
    format_instructions(instruction_params)

    # create SpecialIssueChange record to log the changes
    SpecialIssueChange.create!(
      issue_id: issue.id,
      appeal_id: appeal.id,
      appeal_type: "LegacyAppeal",
      task_id: task.id,
      created_at: Time.zone.now.utc,
      created_by_id: current_user.id,
      created_by_css_id: current_user.css_id,
      original_mst_status: issue.mst_status,
      original_pact_status: issue.pact_status,
      updated_mst_status: updated_mst_status,
      updated_pact_status: updated_pact_status,
      change_category: change_category
    )
  end

  # formats and saves task instructions
  # rubocop:disable Metrics/AbcSize
  # :reek:FeatureEnvy
  def format_instructions(inst_params)
    note = params[:issues][:note].nil? ? "N/A" : params[:issues][:note]
    # use codes from params to get descriptions
    # opting to use params vs issue model to capture in-flight issue changes
    program_code = params[:issues][:program]
    issue_code = params[:issues][:issue]

    # line up param codes to their descriptions
    param_issue = Constants::ISSUE_INFO[program_code]
    iss = param_issue["levels"][issue_code]["description"] unless issue_code.nil?

    issue_code_message = build_issue_code_message(issue_code, param_issue)

    # format the task instructions and close out
    set = CaseTimelineInstructionSet.new(
      change_type: inst_params[:change_category],
      issue_category: [
        "Benefit Type: #{param_issue['description']}\n",
        "Issue: #{iss}\n",
        "Code: #{issue_code_message}\n",
        "Note: #{note}\n"
      ].compact.join("\r\n"),
      benefit_type: "",
      original_mst: inst_params[:issue].mst_status,
      original_pact: inst_params[:issue].pact_status,
      edit_mst: inst_params[:updated_mst_status],
      edit_pact: inst_params[:updated_pact_status]
    )
    inst_params[:task].format_instructions(set)
    inst_params[:task].completed!
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # builds issue code on IssuesUpdateTask for MST/PACT changes
  def build_issue_code_message(issue_code, param_issue)
    level_1_code = params[:issues][:level_1]
    diagnostic_code = params[:issues][:level_2]

    # use diagnostic code message if it exists
    if !diagnostic_code.blank?
      diagnostic_description = Constants::DIAGNOSTIC_CODE_DESCRIPTIONS[diagnostic_code]["staff_description"]
      [diagnostic_code, diagnostic_description].join(" - ")
    # use level 1 message if it exists
    elsif !level_1_code.blank?
      level_1_description = param_issue["levels"][issue_code]["levels"][level_1_code]["description"]
      [level_1_code, level_1_description].join(" - ")
    # return N/A if none exist
    else
      "N/A"
    end
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
