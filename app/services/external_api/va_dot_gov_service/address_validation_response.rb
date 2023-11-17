# frozen_string_literal: true

class ExternalApi::VADotGovService::AddressValidationResponse < ExternalApi::VADotGovService::Response
  def error
    message_error || response_error || foreign_address_error
  end

  def data
    return {} if body[:geocode].nil?

    formatted_valid_address
  end

  private

  # The coordinates_invalid? check prevents the creation of a HearingAdminActionVerifyAddressTask when
  # the response contains valid geographic coordiantes sufficient to complete geomatching
  def message_error
    messages&.find { |message| message.error.present? && coordinates_invalid? }&.error
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

  # When using only an appellant's zip code to validate an address, an invalid zip code will return
  # float values of 0.0 for both latitude and longitude
  def coordinates_invalid?
    return true if body[:geocode].nil?

    [body[:geocode][:latitude], body[:geocode][:longitude]] == [0.0, 0.0]
  end

  def foreign_address_error
    if coordinates_invalid? && address_type == "International"
      Caseflow::Error::VaDotGovForeignVeteranError.new(
        code: 500,
        message: "Appellant address is not in US territories."
      )
    end
  end

  def address_type
    body.dig(:addressMetaData, :addressType)
  end
end
