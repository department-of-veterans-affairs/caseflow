# frozen_string_literal: true

class Api::V1::MpiController < Api::ApplicationController
  # {POST Method for Veteran ID, Deceased Indicator, Deceased Time}
  def veteran_updates
    veteran = {
      id: allowed_params[:veterans_id],
      deceased_ind: allowed_params[:deceased_ind],
      deceased_time: allowed_params[:deceased_time]
    }

    # result will be true if an update was made, or nil otherwise
    result = VACOLS::Correspondent.update_veteran_nod(veteran)
    render json: { success: result }, status: :ok
  end

  def allowed_params
    params.permit(:veterans_id, :deceased_ind, :deceased_time)
  end
end
