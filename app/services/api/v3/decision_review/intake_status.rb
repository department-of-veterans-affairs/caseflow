# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeStatus
  def initialize(intake)
    @intake = intake
  end

  def render_hash
    {
      json: {
        type: @intake.detail_type,
        id: @intake.detail.uuid,
        attributes: { status: @intake.detail.asyncable_status }
      },
      status: :accepted
    }
  end
end
