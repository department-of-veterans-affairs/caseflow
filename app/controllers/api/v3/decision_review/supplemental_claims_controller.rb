# frozen_string_literal: true

class Api::V3::DecisionReview::SupplementalClaimsController < Api::V3::BaseController
  def show
    render json: {}, status: :ok
  end
end
