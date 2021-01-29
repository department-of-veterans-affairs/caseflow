# frozen_string_literal: true

class Api::V3::DecisionReviews::AppealsController < Api::V3::BaseController
  include ApiV3FeatureToggleConcern

  before_action do
    api_released?(:api_v3_appeals)
  end

  # stub
  def create
    render json: {}, status: :not_found
  end

  # stub
  def show
    render json: {}, status: :not_found
  end
end
