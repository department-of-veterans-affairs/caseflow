# frozen_string_literal: true

require "json"
require "digest"

# Provides access to the VA.gov veteran address verification API and the
# VA facilities API.
#
# Documentation:
#
#   * VA.gov API Service Overview: https://developer.va.gov/explore
#   * VA.gov Facilities API:       https://developer.va.gov/explore/facilities/docs/facilities
#   * VA.gov Veteran Address API:  https://developer.va.gov/explore/verification/docs/address_validation
#
class ExternalApi::VADotGovService
  BASE_URL = ENV["VA_DOT_GOV_API_URL"] || ""
  FACILITY_IDS_ENDPOINT = "va_facilities/v0/ids"
  FACILITIES_ENDPOINT = "va_facilities/v0/facilities"
  ADDRESS_VALIDATION_ENDPOINT = "address_validation/v1/validate"

  class << self
    # :nocov:
    # Gets facilities (including distance) for the specified IDs.
    #
    # @param lat  [Numeric] latitude of starting address (used to compute distance to facility)
    # @param long [Numeric] longitude of starting address (used to compute distance to facility)
    # @param ids  [Array<String, Symbol>] facility ids to find
    #
    # @return     [ExternalApi::VADotGovService::FacilitiesResponse]
    #   An aggregated API response that contains all the queried facilities (see #send_facilities_request)
    #
    # @raise      [Caseflow::Error::VaDotGovMissingFacilityError]
    #   If not all facility ids were found
    def get_distance(lat:, long:, ids:)
      send_facilities_requests(
        ids: ids,
        query: { lat: lat, long: long, ids: ids.join(",") }
      )
    end

    # Gets facilities for the specified IDs.
    #
    # @param ids [Array<String, Symbol>] facility ids to find
    #
    # @return    [ExternalApi::VADotGovService::FacilitiesResponse]
    #   An aggregated API response that contains all the queried facilities (see #send_facilities_request)
    #
    # @raise     [Caseflow::Error::VaDotGovMissingFacilityError]
    #   If not all facility ids were found
    def get_facility_data(ids:)
      send_facilities_requests(
        ids: ids,
        query: { ids: ids.join(",") }
      )
    end

    # Verifies a veteran's address and returns a normalized version of it.
    #
    # @param address [Address] A veteran's address
    #
    # @return        [ExternalApi::VADotGovService::AddressValidationResponse]
    #   A wrapper around the VA.gov API response that includes a normalized version of
    #   the veteran's address
    #
    # API Documentation: https://developer.va.gov/explore/verification/docs/address_validation
    #
    # Expected JSON Response from API:
    #
    # ```
    # {
    #   "address": {
    #     "addressLine1": "string",
    #     "addressLine2": "string",
    #     "addressLine3": "string",
    #     "city": "string",
    #     "country": {
    #       "code": "string",
    #       "fipsCode": "string",
    #       "iso2Code": "string",
    #       "iso3Code": "string",
    #       "name": "string"
    #     },
    #     "county": {
    #       "countyFipsCode": "string",
    #       "name": "string"
    #     },
    #     "internationalPostalCode": "string",
    #     "stateProvince": {
    #       "code": "string",
    #       "name": "string"
    #     },
    #     "zipCode4": "string",
    #     "zipCode5": "string"
    #   },
    #   "addressMetaData": {
    #     "addressType": "string",
    #     "confidenceScore": 0,
    #     "deliveryPointValidation": "CONFIRMED",
    #     "nonPostalInputData": [
    #       "string"
    #     ],
    #     "residentialDeliveryIndicator": "RESIDENTIAL",
    #     "validationKey": 0
    #   },
    #   "geocode": {
    #     "calcDate": "2020-06-17T15:49:59.891Z",
    #     "latitude": 0,
    #     "locationPrecision": 0,
    #     "longitude": 0
    #   },
    #   "messages": [
    #     {
    #       "code": "string",
    #       "key": "string",
    #       "potentiallySelfCorrectingOnRetry": true,
    #       "severity": "INFO",
    #       "text": "string"
    #     }
    #   ]
    # }
    # ```
    def validate_address(address)
      response = send_va_dot_gov_request(address_validation_request(address))

      ExternalApi::VADotGovService::AddressValidationResponse.new(response)
    end

    # Gets full list of facility IDs available from the VA.gov API
    #
    # @param ids [Array<String, Symbol>] facility ids to check
    #
    # @return    [ExternalApi::VADotGovService::FacilitiesIdsResponse]
    #   An API response that contains the full list of facility IDs available at API.gov, and
    #     helper methods to check for missing IDs
    def check_facility_ids(ids: [])
      response = send_facilities_ids_request

      ExternalApi::VADotGovService::FacilitiesIdsResponse.new(response, ids)
    end

    private

    # Queries the VA.gov facilities API.
    #
    # @note Results are cached for 2 hours.
    #
    # @param query [Hash] query parameters
    #
    # @return [ExternalApi::VADotGovService::FacilitiesResponse]
    #   A wrapper of the respone from the API
    #
    # API Documentation: https://developer.va.gov/explore/facilities/docs/facilities
    #
    # Expected JSON Response from API:
    #
    # ```
    # {
    #   "data": [
    #     {
    #       "id": "vha_688",
    #       "type": "va_facilities",
    #       "attributes": {
    #         "name": "Washington VA Medical Center",
    #         "classification": "VA Medical Center (VAMC)",
    #         "website": "http://www.washingtondc.va.gov",
    #         "address": {
    #           "mailing": {
    #             "zip": "20422-0001",
    #             "city": "Washington",
    #             "state": "DC",
    #             "address_1": "50 Irving Street, Northwest",
    #             "address_2": "string",
    #             "address_3": "string"
    #           },
    #           "physical": {
    #             "zip": "20422-0001",
    #             "city": "Washington",
    #             "state": "DC",
    #             "address_1": "50 Irving Street, Northwest",
    #             "address_2": "string",
    #             "address_3": "string"
    #           }
    #         },
    #         "phone": {
    #           "fax": "202-555-1212",
    #           "main": "202-555-1212",
    #           "pharmacy": "202-555-1212",
    #           "after_hours": "202-555-1212",
    #           "patient_advocate": "202-555-1212",
    #           "mental_health_clinic": "202-555-1212",
    #           "enrollment_coordinator": "202-555-1212"
    #         },
    #         "hours": {
    #           "monday": "9AM-5PM",
    #           "tuesday": "9AM-5PM",
    #           "wednesday": "9AM-5PM",
    #           "thursday": "9AM-5PM",
    #           "friday": "9AM-5PM",
    #           "saturday": "Closed",
    #           "sunday": "Closed"
    #         },
    #         "services": {
    #           "other": [
    #             "OnlineScheduling"
    #           ],
    #           "health": [
    #             "Audiology"
    #           ],
    #           "benefits": [
    #             "ApplyingForBenefits"
    #           ],
    #           "last_updated": "2018-01-01"
    #         },
    #         "satisfaction": {
    #           "health": {
    #             "primary_care_urgent": 0.85,
    #             "primary_care_routine": 0.85,
    #             "specialty_care_urgent": 0.85,
    #             "specialty_care_routine": 0.85
    #           },
    #           "effective_date": "2018-01-01"
    #         },
    #         "mobile": false,
    #         "visn": "20",
    #         "facility_type": "va_benefits_facility",
    #         "lat": 38.9311137,
    #         "long": -77.0109110499999,
    #         "wait_times": {
    #           "health": [
    #             {
    #               "service": "Audiology",
    #               "new": 10,
    #               "established": 5
    #             }
    #           ],
    #           "effective_date": "2018-01-01"
    #         },
    #         "active_status": "A",
    #         "operating_status": {
    #           "code": "NORMAL",
    #           "additional_info": "string"
    #         }
    #       }
    #     }
    #   ],
    #   "links": {
    #     "related": "string",
    #     "self": "string",
    #     "first": "string",
    #     "prev": "string",
    #     "next": "string",
    #     "last": "string"
    #   },
    #   "meta": {
    #     "pagination": {
    #       "current_page": 1,
    #       "per_page": 10,
    #       "total_pages": 217,
    #       "total_entries": 2162
    #     },
    #     "distances": [
    #       {
    #         "id": "string",
    #         "distance": 0
    #       }
    #     ]
    #   }
    # }
    # ```
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

    # Queries the VA.gov facilities API for a group of facility ids and pages through
    # the results.
    #
    # @param ids   [Array<String, Symbol>] facility ids to find
    # @param query [Hash] query parameters
    #
    # @return      [ExternalApi::VADotGovService::FacilitiesResponse]
    #   An aggregated API response that contains all the queried facilities (see #send_facilities_request)
    #
    # @raise      [Caseflow::Error::VaDotGovMissingFacilityError]
    #   If not all facility ids were found
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

    # Queries the VA.gov facilities API for a list of facility ids
    #
    # @return      [ExternalApi::VADotGovService::FacilitiesIdsResponse]
    #   An aggregated API response that contains all the queried facilities (see #send_facilities_request)
    def send_facilities_ids_request
      cache_key = "send_facilities_ids_request"
      Rails.cache.fetch(cache_key, expires_in: 2.hours) do
        send_va_dot_gov_request(
          endpoint: FACILITY_IDS_ENDPOINT
        )
      end
    end

    def send_va_dot_gov_request(query: {}, headers: {}, endpoint:, method: :get, body: nil)
      url = URI.escape(BASE_URL + endpoint)
      request = HTTPI::Request.new(url)
      request.query = query
      request.open_timeout = 30
      request.read_timeout = 30
      request.body = body.to_json unless body.nil?
      request.headers = headers.merge(apikey: ENV["VA_DOT_GOV_API_KEY"])

      # Rate limit requests to VA.gov veteran verification API. This is meant to be an aggressive,
      # temporary safety measure because it's more costly (in terms of computing resources) if we
      # hit the rate limit. The sleep will be removed as a part of the work on this issue:
      # https://github.com/department-of-veterans-affairs/caseflow/issues/14710
      #
      # Rate Limit: https://developer.va.gov/explore/verification/docs/veteran_confirmation?version=current
      #
      # > We implemented basic rate limiting of 60 requests per minute. If you exceed this quota,
      # > your request will return a 429 status code. You may petition for increased rate limits by
      # > emailing and requests will be decided on a case by case basis.
      sleep 1

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

    # Builds a request for the VA.gov veteran address validation endpoint.
    #
    # @param address [Address] The veteran's address
    #
    # @return        [Hash] The payload to send to the VA.gov API
    def address_validation_request(address)
      {
        body: {
          requestAddress: {
            addressLine1: address.address_line_1,
            addressLine2: address.address_line_2,
            addressLine3: address.address_line_3,
            city: address.city,
            zipCode5: address.zip,
            zipCode4: address.zip4,
            international_postal_code: address.international_postal_code,
            stateProvince: { name: address.state_name, code: address.state },
            requestCountry: { countryName: address.country_name, countryCode: address.country },
            addressPOU: address.address_pou
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
