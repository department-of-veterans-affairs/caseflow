# frozen_string_literal: true

require "json"
require "digest"

class ExternalApi::VADotGovService
  BASE_URL = ENV["VA_DOT_GOV_API_URL"] || ""
  FACILITIES_ENDPOINT = "va_facilities/v0/facilities"
  ADDRESS_VALIDATION_ENDPOINT = "address_validation/v1/validate"

  class << self
    # :nocov:
    def get_distance(lat:, long:, ids:)
      send_facilities_requests(
        ids: ids,
        query: { lat: lat, long: long, ids: ids.join(",") }
      )
    end

    def get_facility_data(ids:)
      send_facilities_requests(
        ids: ids,
        query: { ids: ids.join(",") }
      )
    end

    def validate_address(address)
      response = send_va_dot_gov_request(address_validation_request(address))

      ExternalApi::VADotGovService::AddressValidationResponse.new(response)
    end

    private

    def send_facilities_request(query:)
      cache_key = "send_facilities_request_#{Digest::SHA1.hexdigest(query.to_json)}"
      response = Rails.cache.fetch(cache_key, expires_in: 2.hours) do
        send_va_dot_gov_request(
          query: query,
          endpoint: FACILITIES_ENDPOINT
        )
      end

      ExternalApi::VADotGovService::FacilitiesResponse.new(response)
    end

    def send_facilities_requests(ids:, query:)
      page = 1
      remaining_ids = ids
      response = nil

      until remaining_ids.empty? || response.try(:next?) == false || response.try(:success?) == false
        response = send_facilities_request(query: query.merge(page: page, per_page: 200)).merge(response)

        remaining_ids -= response.data.pluck(:facility_id)

        page += 1
      end

      if !remaining_ids.empty? && response.success?
        fail Caseflow::Error::VaDotGovMissingFacilityError,
             message: "Missing facility ids #{remaining_ids.join(',')}",
             code: 500
      end

      track_pages(page)

      response
    end

    def send_va_dot_gov_request(query: {}, headers: {}, endpoint:, method: :get, body: nil)
      url = URI.escape(BASE_URL + endpoint)
      request = HTTPI::Request.new(url)
      request.query = query
      request.open_timeout = 30
      request.read_timeout = 30
      request.body = body.to_json unless body.nil?
      request.headers = headers.merge(apikey: ENV["VA_DOT_GOV_API_KEY"])

      MetricsService.record("api.va.gov #{method.to_s.upcase} request to #{url}",
                            service: :va_dot_gov,
                            name: endpoint) do
        case method
        when :get
          HTTPI.get(request)
        when :post
          HTTPI.post(request)
        end
      end
    end

    def address_validation_request(address)
      {
        body: {
          requestAddress: {
            addressLine1: address.address_line_1,
            addressLine2: address.address_line_2,
            addressLine3: address.address_line_3,
            city: address.city,
            stateProvince: { code: address.state },
            requestCountry: { country_code: address.country },
            zipCode5: address.zip
          }
        },
        headers: {
          "Content-Type": "application/json", Accept: "application/json"
        },
        endpoint: ADDRESS_VALIDATION_ENDPOINT, method: :post
      }
    end

    def track_pages(pages)
      DataDogService.emit_gauge(
        metric_group: "service",
        metric_name: "pages_requested",
        metric_value: pages,
        app_name: RequestStore[:application],
        attrs: {
          service: "va_dot_gov"
        }
      )
    end
    # :nocov:
  end
end
