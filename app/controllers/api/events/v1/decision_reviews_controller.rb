# frozen_string_literal: true

class Api::Events::V1::DecisionReviewsController < Api::ApplicationController
  before_action :verify_authentication_token
  protect_from_forgery with: :null_session

  def decision_review_created
    render json: { message: "Decision Review Created" }, status: :created
  end
end
