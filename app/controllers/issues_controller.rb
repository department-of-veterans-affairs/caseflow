class IssuesController < ApplicationController
  before_action :verify_queue_phase_two

  def create
    return record_not_found unless appeal
    record = Issue.create!(current_user.css_id, create_params)
    return issue_creation_error unless record
    render json: { issue: record }, status: :created
  end

  private

  def appeal
    @appeal ||= Appeal.find(params[:appeal_id])
  end

  def create_params
    params.require("issues").permit(:program,
                                    :issue,
                                    :level_1,
                                    :level_2,
                                    :level_3,
                                    :note)
      .merge(vacols_id: appeal.vacols_id)
  end

  def issue_creation_error
    render json: {
      "errors": [
        "title": "Error Creating VACOLS Issue",
        "detail": "Errors occured when creating an issue"
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
