# frozen_string_literal: true

class ExternalApi::VADotGovService::FacilitiesResponseHelper < ExternalApi::VADotGovService::ResponseHelper
  def facilities
    return [] if body[:data].blank?

    body[:data].map do |facility|
      format_facility_response(facility, distances[facility[:id]])
    end
  end

  private

  def distances
    Hash[body[:meta][:distances].pluck(:id, :distance)]
  end

  def format_facility_response(facility)
    attrs = facility[:attributes]

    {
      facility_id: facility[:id],
      type: facility[:type],
      facility_type: attrs[:facility_type],
      name: attrs[:name],
      classification: attrs[:classification],
      address: full_address(
        address_1: attrs[:address][:physical][:address_1],
        address_2: attrs[:address][:physical][:address_2],
        address_3: attrs[:address][:physical][:address_3]
      ),
      city: attrs[:address][:physical][:city],
      state: attrs[:address][:physical][:state],
      zip_code: attrs[:address][:physical][:zip],
      lat: attrs[:lat],
      long: attrs[:long],
      distance: distance
    }
  end
end
