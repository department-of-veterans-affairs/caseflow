# frozen_string_literal: true

class Api::V1::MPIController < Api::ApplicationController
  # {POST Method for Veteran ID, Deceased Indicator, Deceased Time}
  def veteran_updates

    id = Correspondent[allowed_params[:veterans_id]]
    
    deceased_ind = Correspondent[allowed_params[:deceasedInd]]
    
    deceased_time = Correspondent[allowed_params[:deceasedTime]]
    
    render json: { success: true }, status: :ok
  end

  def allowed_params
    params.permit(:veterans_id, :deceasedInd, :deceasedTime)
  end
end