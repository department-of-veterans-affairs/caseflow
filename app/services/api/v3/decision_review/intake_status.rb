# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeStatus
  NO_DECISION_REVIEW_HTTP_STATUS = 500
  PROCESSED_HTTP_STATUS = 303
  NOT_PROCESSED_HTTP_STATUS = 200
  NOT_PROCESSED_HTTP_STATUS_FOR_NEW_INTAKE = 202
  NO_DECISION_REVIEW_JSON = {
    errors: [
      {
        status: NO_DECISION_REVIEW_HTTP_STATUS,
        code: :intake_not_connected_to_a_decision_review,
        title: "This intake is not connected to a decision review."
      }
    ]
  }.freeze

  def initialize(intake)
    @intake = intake
  end

  def to_json(*_args)
    decision_review ? decision_review_json : NO_DECISION_REVIEW_JSON
  end

  def http_status
    error_or_processed_status || NOT_PROCESSED_HTTP_STATUS
  end

  def http_status_for_new_intake
    error_or_processed_status || NOT_PROCESSED_HTTP_STATUS_FOR_NEW_INTAKE
  end

  def processed?
    decision_review&.asyncable_status == :processed
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

  def error_or_processed_status
    return NO_DECISION_REVIEW_HTTP_STATUS unless decision_review
    return PROCESSED_HTTP_STATUS if processed?

    nil
  end
end
