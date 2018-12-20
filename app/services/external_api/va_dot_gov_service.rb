require "json"

class ExternalApi::VADotGov
  class << self
    # :nocov:
    def get_distance(point, ids)

      page = 1
      facility_results = []

      while ids.length > 0

        response = send_va_dot_gov_request(
          query: { lat: point[0], long: point[1], page: page },
          endpoint: facilities_endpoint
        )

        resp_body = JSON.parse(response.body)

        check_for_error(response_body: resp_body, code: response.code)
        facilities, distance, total_pages = facility_response_data(resp_body)

        selected_facilities = facilities.select { |facility| ids.include? facility["id"] }

        if !selected_facilities.empty?
          ids -= selected_facilites.pluck("id")
          facility_results += selected_facilities.map do |selected|
              distance = distances.find { |dist| dist["id"] == selected["id"] }
              facility_json(selected, distance)
          end
        end

        page += 1
        break if page > total_pages
        sleep 0.25
      end

      Rails.logger.info("Unable to find api.va.gov facility data for: #{ids.join(', ')}.") if ids.length > 0

      facility_results
    end

    def geocode(address:, city:, state:, country: "USA", zip_code: )
      return [0.0, 0.0]
      response = send_va_dot_gov_request(
        body: {
          requestAddress: {
            addressLine1: address,
            city: city,
            stateProvince: {
              code: state,
            },
            zipCode5: zip_code
          }
        },
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json"
        },
        endpoint: address_validation_endpoint,
        method: :post
      )

      resp_body = JSON.parse(response.body)

      check_for_error(response_body: resp_body, code: response.code)

    end

    private

    def base_url
      "https://staging-api.va.gov/services/"
    end

    def facilities_endpoint
      "va_facilities/v0/facilities"
    end

    def address_validation_endpoint
      "address-validation/v0/validate"
    end

    def facility_resp_data(resp_body)
      [
        resp_body["data"],
        resp_body["meta"]["distances"],
        resp_body["meta"]["pagination"]["total_pages"]
      ]
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

    def send_va_dot_gov_request(query: {}, headers: {}, endpoint:, method: :get, body:)

      url = URI.escape(base_url + endpoint)
      request = HTTPI::Request.new(url)
      request.query = query
      request.open_timeout = 600 # seconds
      request.read_timeout = 600 # seconds
      request.auth.ssl.ssl_version  = :TLSv1_2
      request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]

      request.body = body.to_json if body

      request.headers = headers.merge({ apikey: ENV["VA_DOT_GOV_API_KEY"] })

      MetricsService.record("api.va.gov GET request to #{url}",
                            service: :facilities_locator,
                            name: endpoint) do
        case method
        when :get
          HTTPI.get(request)
        when :post
          HTTPI.post(request)
        end
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
