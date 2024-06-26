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
  FACILITY_IDS_ENDPOINT = "va_facilities/v1/ids"
  FACILITIES_ENDPOINT = "va_facilities/v1/facilities"
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
        query: { lat: lat, long: long, facilityIds: ids.join(",") }
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
        query: { facilityIds: ids.join(",") }
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

    # Verifies a veteran's zip code and returns its associated geographic coordinates in latitude and longitude.
    #
    # @param zip_code [String] A veteran's five-digit zip code
    #
    # @return        [ExternalApi::VADotGovService::AddressValidationResponse]
    #   A wrapper around the VA.gov API response that includes the geocode (latitude and longitude) associated
    #   with the veteran's zip code.
    #
    #   Note: The response will include an "AddressCouldNotBeFound" and "lowConfidenceScore" messages
    #
    # API Documentation: https://developer.va.gov/explore/verification/docs/address_validation
    #
    # Expected JSON Response from API:
    #
    # ```
    # {
    #   "messages": [
    #     {
    #       "code": "ADDRVAL112",
    #       "key": "AddressCouldNotBeFound",
    #       "text": "The Address could not be found",
    #       "severity": "WARN"
    #     },
    #     {
    #       "code": "ADDR306",
    #       "key": "lowConfidenceScore",
    #       "text": "VaProfile Validation Failed: Confidence Score less than 80",
    #       "severity": "WARN"
    #     }
    #   ],
    #   "address": {
    #     "addressLine1": "Address",
    #     "zipCode5": "string",
    #     "stateProvince": {},
    #     "country": {
    #       "name": "United States",
    #       "code": "USA",
    #       "fipsCode": "US",
    #       "iso2Code": "US",
    #       "iso3Code": "USA"
    #     }
    #   },
    #   "geocode": {
    #     "calcDate": "2023-10-12T20:27:04Z",
    #     "latitude": 40.7029,
    #     "longitude": -73.8868
    #   },
    #   "addressMetaData": {
    #     "confidenceScore": 0.0,
    #     "addressType": "Domestic",
    #     "deliveryPointValidation": "MISSING_ZIP",
    #     "validationKey": 359084376
    #   }
    # }
    # ```
    def validate_zip_code(address)
      response = send_va_dot_gov_request(zip_code_validation_request(address))

      ExternalApi::VADotGovService::ZipCodeValidationResponse.new(response)
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
    #   distances values in the meta field are only returned if a lat and long are provided.
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
    #   {
    #     "data": [
    #         {
    #             "id": "vha_688",
    #             "type": "va_facilities",
    #             "attributes": {
    #                 "name": "Washington VA Medical Center",
    #                 "facilityType": "va_health_facility",
    #                 "classification": "VA Medical Center (VAMC)",
    #                 "parent": {
    #                     "id": "vha_688",
    #                     "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688"
    #                 },
    #                 "website": "https://www.va.gov/washington-dc-health-care/locations/washington-va-medical-center/",
    #                 "lat": 38.929401,
    #                 "long": -77.0111955,
    #                 "timeZone": "America/New_York",
    #                 "address": {
    #                     "physical": {
    #                         "zip": "20422-0001",
    #                         "city": "Washington",
    #                         "state": "DC",
    #                         "address1": "50 Irving Street, Northwest"
    #                     }
    #                 },
    #                 "phone": {
    #                     "fax": "202-745-8530",
    #                     "main": "202-745-8000",
    #                     "pharmacy": "202-745-8235",
    #                     "afterHours": "202-745-8000",
    #                     "patientAdvocate": "202-745-8588",
    #                     "enrollmentCoordinator": "202-745-8000 x56333"
    #                 },
    #                 "hours": {
    #                     "monday": "24/7",
    #                     "tuesday": "24/7",
    #                     "wednesday": "24/7",
    #                     "thursday": "24/7",
    #                     "friday": "24/7",
    #                     "saturday": "24/7",
    #                     "sunday": "24/7"
    #                 },
    #                 "operationalHoursSpecialInstructions": [
    #                     "Normal business hours are Monday through Friday, 8:00 a.m. to 4:30 p.m."
    #                 ],
    #                 "services": {
    #                     "health": [
    #                         {
    #                             "name": "Advice nurse",
    #                             "serviceId": "adviceNurse",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/adviceNurse"
    #                         },
    #                         {
    #                             "name": "Anesthesia",
    #                             "serviceId": "anesthesia",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/anesthesia"
    #                         },
    #                         {
    #                             "name": "Audiology and speech",
    #                             "serviceId": "audiology",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/audiology"
    #                         },
    #                         {
    #                             "name": "Cardiology",
    #                             "serviceId": "cardiology",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/cardiology"
    #                         },
    #                         {
    #                             "name": "CaregiverSupport",
    #                             "serviceId": "caregiverSupport",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/caregiverSupport"
    #                         },
    #                         {
    #                             "name": "COVID-19 vaccines",
    #                             "serviceId": "covid19Vaccine",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/covid19Vaccine"
    #                         },
    #                         {
    #                             "name": "Dental/oral surgery",
    #                             "serviceId": "dental",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/dental"
    #                         },
    #                         {
    #                             "name": "Dermatology",
    #                             "serviceId": "dermatology",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/dermatology"
    #                         },
    #                         {
    #                             "name": "Emergency care",
    #                             "serviceId": "emergencyCare",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/emergencyCare"
    #                         },
    #                         {
    #                             "name": "Gastroenterology",
    #                             "serviceId": "gastroenterology",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/gastroenterology"
    #                         },
    #                         {
    #                             "name": "Geriatrics",
    #                             "serviceId": "geriatrics",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/geriatrics"
    #                         },
    #                         {
    #                             "name": "Gynecology",
    #                             "serviceId": "gynecology",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/gynecology"
    #                         },
    #                         {
    #                             "name": "Hematology/oncology",
    #                             "serviceId": "hematology",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/hematology"
    #                         },
    #                         {
    #                             "name": "Homeless Veteran care",
    #                             "serviceId": "homeless",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/homeless"
    #                         },
    #                         {
    #                             "name": "Palliative and hospice care",
    #                             "serviceId": "hospice",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/hospice"
    #                         },
    #                         {
    #                             "name": "Hospital medicine",
    #                             "serviceId": "hospitalMedicine",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/hospitalMedicine"
    #                         },
    #                         {
    #                             "name": "Laboratory and pathology",
    #                             "serviceId": "laboratory",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/laboratory"
    #                         },
    #                         {
    #                             "name": "LGBTQ+ Veteran care",
    #                             "serviceId": "lgbtq",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/lgbtq"
    #                         },
    #                         {
    #                             "name": "MentalHealth",
    #                             "serviceId": "mentalHealth",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/mentalHealth"
    #                         },
    #                         {
    #                             "name": "Minority Veteran care",
    #                             "serviceId": "minorityCare",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/minorityCare"
    #                         },
    #                         {
    #                             "name": "Nutrition, food, and dietary care",
    #                             "serviceId": "nutrition",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/nutrition"
    #                         },
    #                         {
    #                             "name": "Ophthalmology",
    #                             "serviceId": "ophthalmology",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/ophthalmology"
    #                         },
    #                         {
    #                             "name": "Optometry",
    #                             "serviceId": "optometry",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/optometry"
    #                         },
    #                         {
    #                             "name": "Orthopedics",
    #                             "serviceId": "orthopedics",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/orthopedics"
    #                         },
    #                         {
    #                             "name": "Patient advocates",
    #                             "serviceId": "patientAdvocates",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/patientAdvocates"
    #                         },
    #                         {
    #                             "name": "Pharmacy",
    #                             "serviceId": "pharmacy",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/pharmacy"
    #                         },
    #                         {
    #                             "name": "Physical medicine and rehabilitation",
    #                             "serviceId": "physicalMedicine",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/physicalMedicine"
    #                         },
    #                         {
    #                             "name": "Podiatry",
    #                             "serviceId": "podiatry",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/podiatry"
    #                         },
    #                         {
    #                             "name": "Primary care",
    #                             "serviceId": "primaryCare",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/primaryCare"
    #                         },
    #                         {
    #                             "name": "Psychology",
    #                             "serviceId": "psychology",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/psychology"
    #                         },
    #                         {
    #                             "name": "Rehabilitation and extended care",
    #                             "serviceId": "rehabilitation",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/rehabilitation"
    #                         },
    #                         {
    #                             "name": "Suicide prevention",
    #                             "serviceId": "suicidePrevention",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/suicidePrevention"
    #                         },
    #                         {
    #                             "name": "Surgery",
    #                             "serviceId": "surgery",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/surgery"
    #                         },
    #                         {
    #                             "name": "Returning service member care",
    #                             "serviceId": "transitionCounseling",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/transitionCounseling"
    #                         },
    #                         {
    #                             "name": "Transplant surgery",
    #                             "serviceId": "transplantSurgery",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/transplantSurgery"
    #                         },
    #                         {
    #                             "name": "Urology",
    #                             "serviceId": "urology",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/urology"
    #                         },
    #                         {
    #                             "name": "Women Veteran care",
    #                             "serviceId": "womensHealth",
    #                             "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services/womensHealth"
    #                         }
    #                     ],
    #                     "link": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities/vha_688/services",
    #                     "lastUpdated": "2024-03-03"
    #                 },
    #                 "satisfaction": {
    #                     "health": {
    #                         "primaryCareUrgent": 0.7699999809265137,
    #                         "primaryCareRoutine": 0.7300000190734863,
    #                         "specialtyCareUrgent": 0.6499999761581421,
    #                         "specialtyCareRoutine": 0.699999988079071
    #                     },
    #                     "effectiveDate": "2024-02-08"
    #                 },
    #                 "mobile": false,
    #                 "operatingStatus": {
    #                     "code": "NORMAL",
    #                     "supplementalStatus": [
    #                         {
    #                             "id": "COVID_MEDIUM",
    #                             "label": "COVID-19 health protection: Levels medium"
    #                         }
    #                     ]
    #                 },
    #                 "visn": "5"
    #             }
    #         }
    #     ],
    #     "links": {
    #         "self": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities?facilityIds=vha_688",
    #         "first": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities?facilityIds=vha_688",
    #         "last": "https://sandbox-api.va.gov/services/va_facilities/v1/facilities?facilityIds=vha_688"
    #     },
    #     "meta": {
    #         "pagination": {
    #             "currentPage": 1,
    #             "perPage": 10,
    #             "totalPages": 1,
    #             "totalEntries": 1
    #         },
    #         "distances": [
    #             {
    #                 "id": "vha_688",
    #                 "distance": 5522.71
    #             }
    #         ]
    #     }
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
      url = URI::DEFAULT_PARSER.escape(BASE_URL + endpoint)
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
            internationalPostalCode: address.international_postal_code,
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

    # Builds a request for the VA.gov veteran address validation endpoint using only the veteran's five-digit zip code.
    # This will return "AddressCouldNotBeFound" and "lowConfidenceScore" messages. However, given a valid zip code, the
    # response body will include valid coordinates for latitude and longitude.
    #
    # Note 1: Hard code placeholder string for addressLine1 to avoid "InvalidRequestStreetAddress" error
    # Note 2: Include country name to ensure foreign addresses are properly handled
    #
    # @param address [Address] The veteran's address
    #
    # @return        [Hash] The payload to send to the VA.gov API
    def zip_code_validation_request(address)
      {
        body: {
          requestAddress: {
            addressLine1: "address",
            zipCode5: address.zip,
            requestCountry: { countryName: address.country }
          }
        },
        headers: {
          "Content-Type": "application/json", Accept: "application/json"
        },
        endpoint: ADDRESS_VALIDATION_ENDPOINT, method: :post
      }
    end

    def track_pages(pages)
      MetricsService.emit_gauge(
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
