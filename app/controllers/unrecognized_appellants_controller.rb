# frozen_string_literal: true

class UnrecognizedAppellantsController < ApplicationController
  def update
    unrecognized_appellant = UnrecognizedAppellant.find(params[:unrecognized_appellant_id])

    if unrecognized_appellant.update_with_versioning!(unrecognized_appellant_params)
      render json: unrecognized_appellant, include: [:unrecognized_party_detail]
    else
      render json: unrecognized_appellant, status: :bad_request
    end
  end

  private

  def unrecognized_appellant_params
    params.require("unrecognized_appellant").permit(
      :relationship,
      unrecognized_party_detail: [
                                   :name, :middle_name, :last_name, :suffix, :address_line_1, :address_line_2,
                                   :address_line_3, :city, :state, :zip, :country, :phone_number, :email_address
      ]
    )
  end
end
