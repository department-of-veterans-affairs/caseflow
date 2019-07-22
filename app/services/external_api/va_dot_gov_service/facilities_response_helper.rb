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

  def address(address)
    {
      address: full_address(
        address[:address_1],
        address[:address_2],
        address[:address_3]
      ),
      city: address[:city],
      state: address[:state],
      zip_code: address[:zip]
    }
  end

  def attributes(attrs)
    {
      facility_type: attrs[:facility_type],
      name: attrs[:name],
      classification: attrs[:classification],
      lat: attrs[:lat],
      long: attrs[:long]
    }.merge(address(attrs[:address][:physical]))
  end

  def format_facility_response(facility, distance)
    {
      facility_id: facility[:id],
      type: facility[:type],
      distance: distance
    }.merge(attributes(facility[:attributes]))
  end
end
