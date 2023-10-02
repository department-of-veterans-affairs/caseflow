# frozen_string_literal: true

class Api::V3::External::VeteransController < Api::V3::BaseController
  def decision_reviews
    @veteran = Veteran.find(params[:id])
    render json: Api::V3::External::IssueMerger.merge(@veteran)
  end
end
