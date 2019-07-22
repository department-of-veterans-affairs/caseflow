# frozen_string_literal: true

class ExternalApi::VADotGovService::Vet360ResponseHelper < ExternalApi::VADotGovService::ResponseHelper
  def valid_address
    {
      lat: body[:geocode][:latitude],
      long: body[:geocode][:longitude],
      city: body[:address][:city],
      full_address: full_address(
        address_1: body[:address][:addressLine1],
        address_2: body[:address][:addressLine2],
        address_3: body[:address][:addressLine3]
      ),
      country_code: body[:address][:country][:fipsCode],
      state_code: body[:address][:stateProvince][:code],
      zip_code: body[:address][:zipCode5]
    }
  end
end
