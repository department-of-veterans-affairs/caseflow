# frozen_string_literal: true

class Api::V1::CmpController < Api::ApplicationController
  def upload
    status = if validate_payload?
               :ok
             else
               :bad_request
             end

    render json: { result: "test" }, status: status
  rescue StandardError => error
    raise error
  end

  private

  def upload_params
    params.permit(:payload, file: [])
  end

  def validate_payload?
    payload = JSON.parse(upload_params[:payload])

    validate_provider_data?(payload[:providerData]) if payload.present?
  end

  def validate_provider_data?(provider_data)
    return false if provider_data.blank?

    Rails.logger("provider data is #{provider_data}")
    true
  end
end
