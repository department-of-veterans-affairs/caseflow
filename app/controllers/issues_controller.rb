# frozen_string_literal: true

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

    Issue.update_in_vacols!(
      vacols_id: appeal.vacols_id,
      vacols_sequence_id: params[:vacols_sequence_id],
      issue_attrs: issue_params
    )
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
