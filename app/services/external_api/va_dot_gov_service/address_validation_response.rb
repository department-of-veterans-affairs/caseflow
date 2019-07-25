# frozen_string_literal: true

class ExternalApi::VADotGovService::AddressValidationResponse < ExternalApi::VADotGovService::Response
  def error
    message_error || fail_if_response_error
  end

  def valid_address
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

  def formatted_valid_address
    {
      lat: body[:geocode][:latitude],
      long: body[:geocode][:longitude],
      city: body[:address][:city],
      full_address: ExternalApi::VADotGovService::Response.full_address(
        body[:address][:addressLine1],
        body[:address][:addressLine2],
        body[:address][:addressLine3]
      ),
      country_code: body[:address][:country][:fipsCode],
      state_code: body[:address][:stateProvince][:code],
      zip_code: body[:address][:zipCode5]
    }
  end
end
