# frozen_string_literal: true

class Api::Events::V1::DecisionReviewsController < ApplicationController
  before_action :authenticate_microservice!
  protect_from_forgery with: :null_session

  def decision_review_created
    render json: { message: "Decision Review Created" }, status: :created
  end
end
