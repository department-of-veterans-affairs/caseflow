# frozen_string_literal: true

class ExternalApi::VADotGovService::FacilitiesResponse < ExternalApi::VADotGovService::Response
  def next?
    body[:link]&.dig(:next).present?
  end

  def facilities
    return [] if body[:data].blank?

    body[:data].map do |facility|
      Facility.new(facility, distances[facility[:id]]).format
    end
  end

  private

  def distances
    Hash[body[:meta][:distances].pluck(:id, :distance)]
  end

  class Facility
    attr_reader :facility, :distance

    def initialize(facility, distance)
      @facility = facility
      @distance = distance
    end

    def attrs
      facility[:attributes]
    end

    def physical_address
      attrs[:address][:physical]
    end

    def address
      @address ||= Address.new(
        address_line_1: physical_address[:address_1],
        address_line_2: physical_address[:address_2],
        address_line_3: physical_address[:address_3],
        city: physical_address[:city],
        state: physical_address[:state],
        zip: physical_address[:zip]
      )
    end

    def format
      {
        facility_id: facility[:id],
        type: facility[:type],
        distance: distance,
        facility_type: attrs[:facility_type],
        name: attrs[:name],
        classification: attrs[:classification],
        lat: attrs[:lat],
        long: attrs[:long],
        address: address.full_address,
        city: address.city,
        state: address.state,
        zip_code: address.zip
      }
    end
  end
end
