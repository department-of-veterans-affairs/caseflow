# frozen_string_literal: true

require "json"

class ExternalApi::VADotGovService
  BASE_URL = ENV["VA_DOT_GOV_API_URL"] || ""
  FACILITIES_ENDPOINT = "va_facilities/v0/facilities"
  ADDRESS_VALIDATION_ENDPOINT = "address_validation/v1/validate"

  class << self
    # :nocov:
    def get_distance(lat:, long:, ids:)
      result = send_multiple_facility_requests(ids) do |page|
        send_facilities_distance_request(
          latlng: [lat, long], ids: ids.join(","), page: page
        )
      end
      result[:facilities].sort_by { |facility| facility[:distance] }

      result
    end

    def get_facility_data(ids:)
      send_multiple_facility_requests(ids) do |page|
        send_facilities_data_request(
          ids: ids.join(","), page: page
        )
      end
    end

    def validate_address(*args)
      response = send_va_dot_gov_request(validate_address_request(*args))

      vet_360_response = ::Vet360ResponseHelper.new(response)
      { error: vet_360_response.error, valid_address: vet_360_response.valid_address }
    end

    private

    # rubocop:disable Metrics/ParameterLists
    def validate_address_request(
        address_line1:, address_line2: nil,
        address_line3: nil, city:, state:, zip_code:, country:
      )
      # rubocop:enable Metrics/ParameterLists
      {
        body: {
          requestAddress: {
            addressLine1: address_line1, addressLine2: address_line2, addressLine3: address_line3,
            city: city,
            stateProvince: {
              code: state
            },
            requestCountry: {
              country_code: country
            },
            zipCode5: zip_code
          }
        },
        headers: {
          "Content-Type": "application/json", Accept: "application/json"
        },
        endpoint: ADDRESS_VALIDATION_ENDPOINT, method: :post
      }
    end

    def send_multiple_facility_requests(ids)
      page = 1
      facilities = []
      remaining_ids = ids
      result = {}

      until remaining_ids.empty? || result[:has_next] == false
        result = yield(page)

        break if result[:error].present?

        remaining_ids -= result[:facilities].pluck(:facility_id)
        facilities += result[:facilities]

        page += 1
        sleep 1
      end

      error = unless remaining_ids.empty?
                Caseflow::Error::VaDotGovAPIError.new(
                  code: 500,
                  message: "Unable to find api.va.gov facility data for: #{remaining_ids.join(', ')}."
                )
              end

      track_pages(page)

      { error: result[:error] || error, facilities: facilities }
    end

    def send_facilities_distance_request(latlng:, ids:, page:)
      response = send_va_dot_gov_request(
        query: { lat: latlng[0], long: latlng[1], page: page, ids: ids, per_page: 50 },
        endpoint: FACILITIES_ENDPOINT
      )

      facilities_response = ::FacilitiesResponseHelper.new(response)

      {
        facilities: facilities_response.facilities,
        has_next: facilities_response.next?,
        error: facilities_response.error
      }
    end

    def send_facilities_data_request(ids:, page:)
      response = send_va_dot_gov_request(
        query: { ids: ids, page: page },
        endpoint: FACILITIES_ENDPOINT
      )

      facilities_response = ::FacilitiesResponseHelper.new(response)

      {
        facilities: facilities_response.facilities,
        has_next: facilities_response.next?,
        error: facilities_response.error
      }
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
