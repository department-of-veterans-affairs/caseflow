# frozen_string_literal: true

class Api::Events::V1::DecisionReviewCreatedController < Api::ApplicationController
  def decision_review_created
    render json: { message: "Decision Review Created" }, status: :created
  end

  def decision_review_created_error
    render json: { message: "Error Creating Decision Review" }, status: :method_not_allowed
  end
end
