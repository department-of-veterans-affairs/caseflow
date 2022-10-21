# frozen_string_literal: true

class Api::V1::MpiController < Api::ApplicationController
  # {POST Method for Veteran ID, Deceased Indicator, Deceased Time}
  def veteran_updates
    # request.uuid is the logged value
    veteran = {
      id: allowed_params[:veterans_id],
      deceased_ind: allowed_params[:deceased_ind],
      deceased_time: allowed_params[:deceased_time]
    }

    result = VACOLS::Correspondent.update_veteran_nod(veteran)
    render json: { success: result }, status: :ok
  end

  def allowed_params
    params.permit(:veterans_id, :deceased_ind, :deceased_time)
  end
end
