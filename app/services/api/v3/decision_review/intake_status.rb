# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeStatus
  SUBMITTED_HTTP_STATUS = 303
  NOT_SUBMITTED_HTTP_STATUS = 200
  NO_DECISION_REVIEW_HTTP_STATUS = 500

  def initialize(intake)
    @intake = intake.reload
  end

  def to_json(*_args)
    decision_review ? decision_review_json : no_decision_review_json
  end

  def http_status
    return NO_DECISION_REVIEW_HTTP_STATUS unless decision_review

    submitted? ? SUBMITTED_HTTP_STATUS : NOT_SUBMITTED_HTTP_STATUS
  end

  def decision_review_url
    return nil unless submitted?

    url_for(
      controller: decision_review_controller,
      action: :show,
      id: decision_review.uuid
    )
  end

  private

  attr_reader :intake

  def decision_review
    intake.detail
  end

  def decision_review_controller
    decision_review.class.name.underscore.pluralize.to_sym
  end

  def submitted?
    decision_review&.asyncable_status == :submitted
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
end
