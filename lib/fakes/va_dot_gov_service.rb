# frozen_string_literal: true

class Fakes::VADotGovService < ExternalApi::VADotGovService
  # rubocop:disable Metrics/MethodLength
  def self.send_va_dot_gov_request(endpoint:, query: {}, **_args)
    if endpoint == VADotGovService::FACILITIES_ENDPOINT
      facilities = query[:ids].split(",").map do |id|
        data = fake_facilities_data[:data][0]
        data["id"] = id
        data
      end

      distances = query[:ids].split(",").map.with_index do |id, index|
        {
          id: id,
          distance: index
        }
      end

      fake_facilities = fake_facilities_data
      fake_facilities[:data] = facilities
      fake_facilities[:meta][:distances] = distances
      HTTPI::Response.new 200, {}, fake_facilities.to_json
    elsif endpoint == VADotGovService::ADDRESS_VALIDATION_ENDPOINT
      HTTPI::Response.new 200, {}, fake_address_data.to_json
    elsif endpoint == VADotGovService::FACILITY_IDS_ENDPOINT
      HTTPI::Response.new 200, {}, fake_facilities_ids_data.to_json
    end
  end

  def self.fake_address_data
    {
      "messages": [
        {
          "code": "string",
          "key": "string",
          "text": "string",
          "severity": "INFO",
          "potentiallySelfCorrectingOnRetry": true
        }
      ],
      "address": {
        "addressLine1": "8633 Fordham St.",
        "addressLine2": "",
        "addressLine3": "",
        "city": "Deltona",
        "zipCode5": "32738",
        "zipCode4": "2434",
        "internationalPostalCode": "string",
        "county": {
          "name": "Deltona",
          "countyFipsCode": "32738"
        },
        "stateProvince": {
          "name": "Florida",
          "code": "FL"
        },
        "country": {
          "name": "United States",
          "code": "USA",
          "fipsCode": "US",
          "iso2Code": "US",
          "iso3Code": "USA"
        },
      },
      "geocode": {
        "calcDate": "2019-01-03T17:33:57+00:00",
        "locationPrecision": 31.0,
        "latitude": 38.768185,
        "longitude": -77.450033
      },
      "usCongressionalDistrict": "string",
      "addressMetaData": {
        "confidenceScore": 100.0,
        "addressType": "Domestic",
        "deliveryPointValidation": "CONFIRMED",
        "residentialDeliveryIndicator": "RESIDENTIAL",
        "nonPostalInputData": [
          "string"
        ],
        "validationKey": 113_008_568
      }
    }
  end

  def self.fake_facilities_data
    # RO01
    {
      "data": [
        {
          "id": "vba_301",
          "type": "va_facilities",
          "attributes": {
            "name": "Holdrege VA Clinic",
            "facility_type": "va_health_facility",
            "classification": "Primary Care CBOC",
            "website": nil,
            "lat": 40.4454392100001,
            "long": -99.37959413,
            "address": {
              "mailing": {

              },
              "physical": {
                "zip": "68949-1705",
                "city": "Holdrege",
                "state": "NE",
                "address_1": "1118 Burlington Street",
                "address_2": "",
                "address_3": nil
              }
            },
            "phone": {
              "fax": "555-555-3775 x",
              "main": "555-555-3760 x",
              "pharmacy": "555-555-0827 x",
              "after_hours": "555-555-5555 x",
              "patient_advocate": "555-555-5555 x7933",
              "mental_health_clinic": "555-555-5555",
              "enrollment_coordinator": "555-555-5555 x"
            },
            "hours": {
              "friday": "800AM-430PM",
              "monday": "800AM-430PM",
              "sunday": "-",
              "tuesday": "800AM-430PM",
              "saturday": "-",
              "thursday": "800AM-430PM",
              "wednesday": "800AM-430PM"
            },
            "services": {
              "other": [
                "Online Scheduling"
              ],
              "health": %w[
                MentalHealthCare
                PrimaryCare
                Audiology
                Cardiology
              ],
              "last_updated": "2019-01-02"
            },
            "satisfaction": {
              "health": {

              },
              "effective_date": nil
            },
            "wait_times": {
              "health": [],
              "effective_date": "2018-12-24"
            }
          }
        }
      ],
      "links": {
        "self": "https://api.vets.gov/services/",
        "first": "https://api.vets.gov/services/",
        "prev": nil,
        "next": nil,
        "last": "https://api.vets.gov/services/"
      },
      "meta": {
        "pagination": {
          "current_page": 1,
          "per_page": 30,
          "total_pages": 77,
          "total_entries": 2289
        },
        "distances": [
          {
            "id": "vba_301",
            "distance": 60.07
          }
        ]
      }
    }
  end

  def self.fake_facilities_ids_data
    {
      "data": %w[
        vba_301 vba_304 vba_304a vba_304h vba_304j
        vba_304k vba_306 vba_306a vba_306b vba_306d
        vba_306f vba_306g vba_306h vba_306i vba_306j
        vba_307 vba_307a vba_307b vba_307c vba_307d
        vba_307e vba_307f vba_308 vba_308b vba_308d
        vba_309 vba_310 vba_310a vba_310c vba_310d
        vba_310e vba_310g vba_311 vc_3121OS vc_3122OS
        vba_313 vba_313a vba_313b vba_313c vba_313d
        vba_313e vba_313f vba_314 vba_314aa vba_314ab
        vba_314b vba_314c vba_314e vba_314g vba_314h
        vba_314i vba_314j vba_314k vba_314l vba_314m
        vba_314n vba_314o vba_314q vba_314v vba_315
        vba_315d vba_315e vba_315f vba_316 vba_316a
        vba_316b vba_316c vba_316d vba_316e vba_316f
        vba_316g vba_316h vba_316i vba_316j vba_316k
        vba_316n vba_317 vba_317a vba_317b vba_317c
        vba_317d vba_317e vba_317f vba_317g vba_317h
        vba_317i vba_317j vba_317k vba_317m vba_317o
        vba_317p vba_317q vba_317r vba_317s vba_317t
        vba_317u vba_318 vba_318a vba_318c vba_318d
        vba_318e vba_318f vba_318h vba_318l vba_318m
        vba_319 vba_319a vba_319b vba_319c vba_319d
        vba_319e vba_319f vba_319g vba_319h vba_320
      ]
    }
  end
  # rubocop:enable Metrics/MethodLength
end
