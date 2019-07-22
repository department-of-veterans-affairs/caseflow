# frozen_string_literal: true

class ExternalApi::VADotGovService::Vet360Response < ExternalApi::VADotGovService::Response
  def valid_address
    return {} if body[:geocode].nil?

    formatted_valid_address
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
