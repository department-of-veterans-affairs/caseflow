# frozen_string_literal: true

class UnrecognizedAppellantsController < ApplicationController
  before_action :find_unrecognized_appellant, only: [:update_power_of_attorney]
  before_action :prevent_update_if_poa_exists, only: [:update_power_of_attorney]

  def update
    unrecognized_appellant = UnrecognizedAppellant.find(params[:id])
    if unrecognized_appellant.update_with_versioning!(unrecognized_appellant_params, current_user)
      render json: unrecognized_appellant, include: [:unrecognized_party_detail]
    else
      render json: unrecognized_appellant, status: :bad_request
    end
  end

  def update_power_of_attorney
    if @unrecognized_appellant.update_power_of_attorney!(unrecognized_appellant_params)
      render json: @unrecognized_appellant, include: [:unrecognized_power_of_attorney]
    else
      render json: @unrecognized_appellant, status: :bad_request
    end
  end

  private

  def prevent_update_if_poa_exists
    render json: { message: "POA already exists" }, status: :bad_request if @unrecognized_appellant.power_of_attorney
  end

  def find_unrecognized_appellant
    @unrecognized_appellant = UnrecognizedAppellant.find(params[:unrecognized_appellant_id])
  end

  def unrecognized_appellant_params
    params.require("unrecognized_appellant").permit(
      :relationship,
      :poa_participant_id,
      unrecognized_party_detail: unrecognized_party_details,
      unrecognized_power_of_attorney: unrecognized_party_details
    )
  end

  def unrecognized_party_details
    [
      :party_type, :name, :middle_name, :last_name, :suffix, :address_line_1, :address_line_2, :date_of_birth,
      :address_line_3, :city, :state, :zip, :country, :phone_number, :email_address
    ]
  end
end
