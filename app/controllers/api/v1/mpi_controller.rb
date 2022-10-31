# frozen_string_literal: true

class Api::V1::MpiController < Api::ApplicationController
  # {POST Method for Veteran ID, Deceased Indicator, Deceased Time}
  def veteran_updates
    veteran = {
      id: allowed_params[:veterans_id],
      deceased_ind: allowed_params[:deceased_ind],
      deceased_time: allowed_params[:deceased_time]
    }

    update_veteran = MpiUpdatePersonEvent.create(api_key: api_key, created_at: Time.zone.now)

    if veteran[:deceased_ind] == "true"
      update_veteran.update!(update_type: :already_deceased, completed_at: Time.zone.now, info: veteran)
    else
      update_veteran.update!(update_type: :missing_deceased_info, completed_at: Time.zone.now, info: veteran)
    end

    # result will be 1 if an update was made, or nil otherwise
    result = VACOLS::Correspondent.update_veteran_nod(veteran)
    render json: { success: result }, status: :ok
  end

  def allowed_params
    params.permit(:veterans_id, :deceased_ind, :deceased_time)
  end
end
