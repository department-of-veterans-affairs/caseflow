# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeStatusesController < Api::V3::BaseController
  def show
    render status: :ok
  end
end
