# frozen_string_literal: true

class Api::Events::V1::DecisionReviewsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :decision_review_created

  before_action :authenticate_microservice!

  def decision_review_created
    render json: { message: "Decision Review Created" }, status: :created
  end

end
