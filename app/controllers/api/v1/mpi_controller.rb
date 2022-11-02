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
    if result != :no_veteran
      updated_veteran = VACOLS::Correspondent.find_veteran(veteran[:id])
      info_column = {
        veteran: veteran[:id],
        updated_veteran: updated_veteran.rows.first[1]
      }
    else
      info_column = {
        veteran: veteran[:id]
      }
    end
    info_column[:updated_column] = "deceased_time" if result == :successful
    mpi_update.update!(update_type: result, completed_at: Time.zone.now, info: info_column)
    render json: { success: result }, status: :ok
  rescue StandardError => error
    mpi_update.update!(update_type: error, completed_at: Time.zone.now, info: { veteran: veteran, error: error })
    raise error
  end

  def allowed_params
    params.permit(:veterans_id, :deceased_ind, :deceased_time)
  end
end
