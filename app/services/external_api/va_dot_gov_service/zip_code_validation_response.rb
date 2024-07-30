# frozen_string_literal: true

# Inherits most of its behavior from AddressValidationResponse, but redefines a successful response
# as one where a zip code returns valid geographic coordinates (regardless of whether a specific
# addres could be found.

class ExternalApi::VADotGovService::ZipCodeValidationResponse < ExternalApi::VADotGovService::AddressValidationResponse
  def error
    message_error || response_error || foreign_address_error
  end

  private

  # The coordinates_invalid? check prevents the creation of a HearingAdminActionVerifyAddressTask when
  # the response contains valid geographic coordiantes sufficient to complete geomatching
  def message_error
    messages&.find { |message| message.error.present? && coordinates_invalid? }&.error
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
