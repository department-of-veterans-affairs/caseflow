# frozen_string_literal: true

class Api::V1::CmpController < Api::ApplicationController
  def upload
    endpoint_disabled("Payload is valid: #{validate_payload?}")
  rescue StandardError => error
    raise error
  end

  private

  def upload_params
    params.permit(:payload, file: [])
  end

  def validate_payload?
    payload = JSON.parse(upload_params[:payload])

    validate_provider_data?(payload["providerData"]) if payload.present?
  end

  def validate_provider_data?(provider_data)
    return false if provider_data.blank?

    Rails.logger.info("provider data is #{provider_data}")
    true
  end
end
