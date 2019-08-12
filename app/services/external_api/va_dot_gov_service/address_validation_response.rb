# frozen_string_literal: true

class ExternalApi::VADotGovService::AddressValidationResponse < ExternalApi::VADotGovService::Response
  def error
    message_error || response_error
  end

  def data
    return {} if body[:geocode].nil?

    formatted_valid_address
  end

  private

  def message_error
    messages&.find { |message| message.error.present? }&.error
  end

  def messages
    @messages ||= body[:messages]&.map do |message|
      ExternalApi::VADotGovService::ResponseMessage.new(message)
    end
  end

  def address
    @address ||= Address.new(
      address_line_1: body[:address][:addressLine1],
      address_line_2: body[:address][:addressLine2],
      address_line_3: body[:address][:addressLine3],
      city: body[:address][:city],
      state: body[:address][:stateProvince][:code],
      country: body[:address][:country][:fipsCode],
      zip: body[:address][:zipCode5]
    )
  end

  def formatted_valid_address
    {
      lat: body[:geocode][:latitude],
      long: body[:geocode][:longitude],
      city: address.city,
      full_address: address.full_address,
      country_code: address.country,
      state_code: address.state,
      zip_code: address.zip
    }
  end
end
