# frozen_string_literal: true

class Api::V1::MpiController < Api::ApplicationController
  # {POST Method for Veteran ID, Deceased Indicator, Deceased Time}
  def veteran_updates
    id = allowed_params[:veterans_id]
    deceased_ind = allowed_params[:deceased_ind]
    deceased_time = allowed_params[:deceased_time]
    render json: { success: true }, status: :ok
  end

  def allowed_params
    params.permit(:veterans_id, :deceased_ind, :deceased_time)
  end
end
