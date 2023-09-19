# frozen_string_literal: true

class Api::V3::External::VeteransController < Api::V3::BaseController
  def decision_reviews
    @veteran = Veteran.find(params[:id])
    render json: json_decision_review_details
  end

  private

  def json_decision_review_details
    ::Api::V3::External::VeteranSerializer.new(@veteran).serialized_json
  end
end
