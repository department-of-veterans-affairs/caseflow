require "json"

class ExternalApi::VADotGovService
  class << self
    # :nocov:
    def get_distance(point, ids)
      page = 1
      facility_results = []

      until ids.empty?
        results = fetch_facilities_with_ids(
          query: { lat: point[0], long: point[1], page: page },
          ids: ids
        )

        ids -= results[:facilities].pluck(:id)
        facility_results += results[:facilities]

        break if !results[:has_next]
        page += 1
        sleep 1
      end

      Rails.logger.info("Unable to find api.va.gov facility data for: #{ids.join(', ')}.") if !ids.empty?
      facility_results
    end

    def geocode(**args)
      response = send_va_dot_gov_request(
        body: geocode_body(**args),
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json"
        },
        endpoint: address_validation_endpoint,
        method: :post
      )

      resp_body = JSON.parse(response.body)
      check_for_error(response_body: resp_body, code: response.code)

      [resp_body["geocode"]["latitude"], resp_body["geocode"]["longitude"]]
    end

    private

    def base_url
      "https://staging-api.va.gov/services/"
    end

    def facilities_endpoint
      "va_facilities/v0/facilities"
    end

    def address_validation_endpoint
      "address_validation/v0/validate"
    end

    def geocode_body(address:, city:, state:, zip_code:, country: "USA")
      {
        requestAddress: {
          addressLine1: address,
          city: city,
          stateProvince: {
            code: state
          },
          requestCountry: {
            country_code: country
          },
          zipCode5: zip_code
        }
      }
    end

    def facility_response_data(resp_body)
      [
        resp_body["data"],
        resp_body["meta"]["distances"],
        resp_body["meta"]["pagination"]["total_pages"]
      ]
    end

    def facility_json(facility, distance)
      attrs = facility["attributes"]
      dist = distance["distance"] if distance

      {
        id: facility["id"],
        type: facility["type"],
        facility_type: attrs["facility_type"],
        name: attrs["name"],
        classification: attrs["classification"],
        address: attrs["address"]["physical"],
        lat: attrs["lat"],
        long: attrs["long"],
        distance: dist
      }
    end

    def fetch_facilities_with_ids(query:, ids:)
      response = send_va_dot_gov_request(
        query: query,
        endpoint: facilities_endpoint
      )
      resp_body = JSON.parse(response.body)
      check_for_error(response_body: resp_body, code: response.code)

      facilities, distances, total_pages = facility_response_data(resp_body)
      selected_facilities = facilities.select { |facility| ids.include? facility["id"] }

      facilities = selected_facilities.map do |selected|
        distance = distances.find { |dist| dist["id"] == selected["id"] }
        facility_json(selected, distance)
      end

      { facilities: facilities, has_next: query[:page] + 1 <= total_pages }
    end

    def send_va_dot_gov_request(query: {}, headers: {}, endpoint:, method: :get, body: nil)
      url = URI.escape(base_url + endpoint)
      request = HTTPI::Request.new(url)
      request.query = query
      request.open_timeout = 600 # seconds
      request.read_timeout = 600 # seconds
      request.auth.ssl.ssl_version  = :TLSv1_2
      request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]
      request.body = body.to_json unless body.nil?
      request.headers = headers.merge(apikey: ENV["VA_DOT_GOV_API_KEY"])

      MetricsService.record("api.va.gov GET request to #{url}",
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

    def check_for_error(response_body:, code:)
      case code
      when 200 # rubocop:disable Lint/EmptyWhen
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
