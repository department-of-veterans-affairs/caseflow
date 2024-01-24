# frozen_string_literal: true

class Api::Events::V1::DecisionReviewsController < Api::ApplicationController

  def decision_review_created
    render json: { message: "Decision Review Created" }, status: :created
  end
end
