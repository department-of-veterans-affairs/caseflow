class Fakes::VADotGovService < ExternalApi::VADotGovService
  def self.send_va_dot_gov_request(endpoint:, **_args)
    if endpoint == facilities_endpoint
      HTTPI::Response.new 200, {}, fake_facilities_data.to_json
    elsif endpoint == address_validation_endpoint
      HTTPI::Response.new 200, {}, fake_address_data.to_json
    end
  end

  # rubocop:disable Metrics/MethodLength
  def self.fake_address_data
    {
      "address": {
        "county": {
          "name": "Manassas Park City",
          "countyFipsCode": "51685"
        },
        "stateProvince": {
          "name": "Virginia",
          "code": "VA"
        },
        "country": {
          "name": "United States",
          "code": "USA",
          "fipsCode": "US",
          "iso2Code": "US",
          "iso3Code": "USA"
        },
        "addressLine1": "8633 Union Pl",
        "addressLine2": "",
        "addressLine3": "",
        "city": "Manassas Park",
        "zipCode5": "20111",
        "zipCode4": "2434"
      },
      "geocode": {
        "calcDate": "2019-01-03T17:33:57+00:00",
        "locationPrecision": 31.0,
        "latitude": 38.768185,
        "longitude": -77.450033
      },
      "addressMetaData": {
        "confidenceScore": 100.0,
        "addressType": "Domestic",
        "deliveryPointValidation": "CONFIRMED",
        "residentialDeliveryIndicator": "RESIDENTIAL",
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
  # rubocop:enable Metrics/MethodLength
end
