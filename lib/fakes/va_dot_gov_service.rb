class Fakes::VADotGovService < ExternalApi::VADotGovService
  def self.get_distance(_point, _ids)
    [
      {
        "id": "vha_688",
        "type": "va_facilities",
        "name": "Washington VA Medical Center",
        "facility_type": "va_health_facility",
        "classification": "VA Medical Center (VAMC)",
        "lat": 38.9311137,
        "long": -77.0109110499999,
        "distance": 500,
        "address": {
          "address_1": "50 Irving Street, Northwest",
          "address_2": "string",
          "address_3": "string",
          "city": "Washington",
          "state": "DC",
          "zip": "20422-0001"
        }
      }
    ]
  end

  def self.geocode(*)
    [0.0, 0.0]
  end
end
