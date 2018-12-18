require "json"

class ExternalApi::FacilitiesLocatorService
  class << self
    # :nocov:
    def get_distance(point, ids)
      response = send_facility_request(query: { lat: point[0], long: point[1], ids: ids })
      resp_body = JSON.parse(response.body)

      check_for_error(response_body: resp_body, code: response.code)

      facilities = resp_body["data"]
      distances = resp_body["meta"]["distances"]

      facilities.map do |facility|
        distance = distances.select { |dist| dist["id"] == facility["id"] }
        facility_json(facility, distance)
      end
    end

    private

    def base_url
      "api.va.gov/services/"
    end

    def endpoint
      "va_facilities/v0/facilities"
    end

    def facility_json(facility, _distance)
      attrs = facility["attributes"]
      distance = _distance["distance"] if _distance

      {
        id: facility["id"],
        type: facility["type"],
        facility_type: attrs["facility_type"],
        name: attrs["name"],
        classification: attrs["classification"],
        address: attrs["address"]["physical"],
        lat: attrs["lat"],
        long: attrs["long"],
        distance: distance
      }
    end

    def send_facility_request(query: {}, headers: {})

      url = URI.escape(base_url + endpoint)
      request = HTTPI::Request.new(url)
      request.query = query.merge({ apikey: ENV["VA_DOT_GOV_API_KEY"] })
      request.open_timeout = 600 # seconds
      request.read_timeout = 600 # seconds
      request.auth.ssl.ssl_version  = :TLSv1_2
      request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]

      request.headers = headers
      MetricsService.record("api.va.gov GET request to #{url}",
                            service: :facilities_locator,
                            name: endpoint) do
        HTTPI.post(request)
      end
    end

    def check_for_error(response_body:, code:)
      case code
      when 200
      when 400
        fail Caseflow::Error::VaDotGovRequestError, code: code, message: response_body
      when 500
        fail Caseflow::Error::VaDotGovServerError, code: 502, message: response_body
      else
        msg = "Error: #{response_body}, HTTP code: #{code}"
        fail Caseflow::Error::VaDotGovServerError, code: 502, message: msg
      end
    end
    # :nocov:
  end
end
