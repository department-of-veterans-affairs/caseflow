# frozen_string_literal: true

class Api::V1::MpiController < Api::ApplicationController
  # {POST Method for Veteran ID, Deceased Indicator, Deceased Time}
  def veteran_updates
    veteran = {
      id: allowed_params[:veterans_id],
      deceased_ind: allowed_params[:deceased_ind],
      deceased_time: allowed_params[:deceased_time]
    }

    mpi_update = MpiUpdatePersonEvent.create!(api_key: api_key, created_at: Time.zone.now, update_type: :started)

    result = VACOLS::Correspondent.update_veteran_nod(veteran)
    mpi_update.update!(update_type: result, completed_at: Time.zone.now, info: veteran)
    render json: { success: result }, status: :ok
  end

  def allowed_params
    params.permit(:veterans_id, :deceased_ind, :deceased_time)
  end
end
