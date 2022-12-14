# frozen_string_literal: true

class Api::V1::MpiController < Api::ApplicationController
  # {POST Method for Veteran ID, Deceased Indicator, Deceased Time}
  def veteran_updates
    veteran = {
      id: allowed_params[:veterans_id],
      deceased_time: allowed_params[:deceased_time],
      pat: allowed_params[:pat]
    }
    puts veteran
    response_info_column = { veteran_id: veteran[:id] }
    mpi_update = MpiUpdatePersonEvent.create!(api_key: api_key, created_at: Time.zone.now, update_type: :started)
    result = VACOLS::Correspondent.update_veteran_nod(veteran).to_sym
    if result == :successful || result == :already_deceased_time_changed
      updated_veteran = VACOLS::Correspondent.find_by(ssn:veteran[:id])
      response_info_column[:updated_column] = "deceased_time"
      response_info_column[:updated_deceased_time] = updated_veteran.sfnod
    end
    mpi_update.update!(update_type: result, completed_at: Time.zone.now, info: response_info_column)
    status = if result == :no_veteran || result == :missing_deceased_info
      :bad_request
    else
      :ok
    end
    render json: { result: result }, status: status
  rescue StandardError => error
    if !Rails.deploy_env?(:prod) && !Rails.deploy_env?(:preprod)
      response_info_column[:error] = error
    end
    mpi_update.update!(update_type: :error, completed_at: Time.zone.now, info: response_info_column)
    raise error
  end

  def allowed_params
    params.permit(:veterans_id, :deceased_time, :pat)
  end
end
