# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeStatus
  NO_DECISION_REVIEW_HTTP_STATUS = 500
  SUBMITTED_HTTP_STATUS = 303
  NOT_SUBMITTED_HTTP_STATUS = 200
  NOT_SUBMITTED_HTTP_STATUS_FOR_NEW_INTAKE = 202

  def initialize(intake)
    @intake = intake
  end

  def to_json(*_args)
    decision_review ? decision_review_json : no_decision_review_json
  end

  def http_status
    error_or_submitted_status || NOT_SUBMITTED_HTTP_STATUS
  end

  def http_status_for_new_intake
    error_or_submitted_status || NOT_SUBMITTED_HTTP_STATUS_FOR_NEW_INTAKE
  end

  def submitted?
    decision_review&.asyncable_status == :submitted
  end

  private

  attr_reader :intake

  def decision_review
    intake.detail
  end

  def decision_review_json
    {
      data: {
        type: decision_review.class.name,
        id: decision_review.uuid,
        attributes: { status: decision_review.asyncable_status }
      }
    }
  end

  def no_decision_review_json
    {
      errors: [
        {
          status: NO_DECISION_REVIEW_HTTP_STATUS,
          code: :intake_not_connected_to_a_decision_review,
          title: "This intake is not connected to a decision review."
        }
      ]
    }
  end

  def error_or_submitted_status
    return NO_DECISION_REVIEW_HTTP_STATUS unless decision_review
    return SUBMITTED_HTTP_STATUS if submitted?

    nil
  end
end
