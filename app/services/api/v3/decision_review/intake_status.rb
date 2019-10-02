# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeStatus
  def initialize(intake)
    @intake = intake
  end

  # returns an array of two elements
  #  [0] the arguments for the render command
  #  [1] any headers that need to be set (will default to {}
  def render_hash_and_headers
    @intake.reload if @intake.id

    return no_decision_review_render_hash_and_headers unless detail

    decision_review_status, http_status, headers = statuses_and_headers

    [
      { # arguments for render
        json: {
          type: intake.detail_type,
          id: detail.uuid,
          attributes: { status: decision_review_status }
        },
        status: http_status
      },
      headers # headers
    ]
  end

  private

  attr_reader :intake

  delegate :detail, to: :intake

  def no_decision_review_render_hash_and_headers
    error = {
      status: 500,
      code: :intake_has_no_associated_decision_review,
      title: "Intake has no associated decision review."
    }

    [
      { json: { errors: [error] }, status: error[:status] }, # arguments for render
      {} # headers
    ]
  end

  def statuses_and_headers
    decision_review_status = detail.asyncable_status
    http_status, headers = if decision_review_status == :submitted
                             [:see_other, { Location: "" }]
                           else
                             [:ok, {}]
                           end

    [decision_review_status, http_status, headers]
  end
end
