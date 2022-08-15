class SplitAppealController < ApplicationController
  def split
    render json: Appeal.find(params[:appeal_id])
  end
end