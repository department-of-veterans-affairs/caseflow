# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeStatus
  def initialize(intake)
    @intake = intake
  end

  def render_hash
    @intake.reload if @intake.id
    {
      json: {
        type: intake.detail_type,
        id: detail&.uuid,
        attributes: { status: detail&.asyncable_status }
      },
      status: :accepted
    }
  end

  private

  attr_reader :intake

  delegate :detail, to: :intake
end
