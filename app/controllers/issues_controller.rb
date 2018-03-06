class IssuesController < ApplicationController
  before_action :verify_queue_phase_two

  def create
    return record_not_found unless appeal
    record = Issue.create!(css_id: current_user.css_id, issue_hash: create_params)
    return issue_error("Errors occured when creating an issue in VACOLS") unless record
    render json: { issue: record }, status: :created
  end

  def update
    return record_not_found unless appeal

    record = Issue.update!(
      css_id: current_user.css_id,
      vacols_id: appeal.vacols_id,
      vacols_sequence_id: params[:vacols_sequence_id],
      issue_hash: general_params
    )
    return issue_error("Errors occured when updating an issue in VACOLS") unless record
    render json: { issue: record }, status: :ok
  end

  private

  def appeal
    @appeal ||= Appeal.find(params[:appeal_id])
  end

  def general_params
    params.require("issues").permit(:note,
                                    program: [:description, :code],
                                    issue: [:description, :code],
                                    level_1: [:description, :code],
                                    level_2: [:description, :code],
                                    level_3: [:description, :code])
  end

  def create_params
    general_params.merge(vacols_id: appeal.vacols_id)
  end

  def issue_error(message)
    render json: {
      "errors": [
        "title": "Error",
        "detail": message
      ]
    }, status: 400
  end

  def record_not_found
    render json: {
      "errors": [
        "title": "Record Not Found",
        "detail": "Record with that ID is not found"
      ]
    }, status: 404
  end
end
