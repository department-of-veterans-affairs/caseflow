require "json"

class ExternalApi::VADotGovService
  class << self
    # :nocov:
    def get_distance(lat:, long:, ids:)
      page = 1
      facility_results = []
      remaining_ids = ids

      until remaining_ids.empty?
        results = fetch_facilities_with_ids(
          query: { lat: lat, long: long, page: page },
          ids: remaining_ids
        )

        remaining_ids -= results[:facilities].pluck(:id)
        facility_results += results[:facilities]

        break if !results[:has_next]
        page += 1
        sleep 1
      end

      unless remaining_ids.empty?
        msg = "Unable to find api.va.gov facility data for: #{remaining_ids.join(', ')}."
        fail Caseflow::Error::VaDotGovAPIError, code: 500, message: msg
      end

      facility_results
    end

    # rubocop:disable Metrics/ParameterLists
    def geocode(
        address_line1:, address_line2: nil,
        address_line3: nil, city:, state:, zip_code:, country:
    )
      # rubocop:enable Metrics/ParameterLists
      response = send_va_dot_gov_request(
        body: geocode_body(
          address_line1: address_line1, address_line2: address_line2,
          address_line3: address_line3, city: city,
          state: state, zip_code: zip_code, country: country
        ),
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
      ENV["VA_DOT_GOV_API_URL"] || ""
    end

    def facilities_endpoint
      "va_facilities/v0/facilities"
    end

    def address_validation_endpoint
      "address_validation/v1/validate"
    end

    # rubocop:disable Metrics/ParameterLists
    def geocode_body(
        address_line1:, address_line2: nil,
        address_line3: nil, city:, state:, zip_code:, country:
    )
      # rubocop:enable Metrics/ParameterLists
      {
        requestAddress: {
          addressLine1: address_line1,
          addressLine2: address_line2,
          addressLine3: address_line3,
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

      facilities = resp_body["data"]
      distances = resp_body["meta"]["distances"]
      has_next = !resp_body["links"]["next"].nil?
      selected_facilities = facilities.select { |facility| ids.include? facility["id"] }

      facilities_result = selected_facilities.map do |selected|
        distance = distances.find { |dist| dist["id"] == selected["id"] }
        facility_json(selected, distance)
      end

      { facilities: facilities_result, has_next: has_next }
    end

    def send_va_dot_gov_request(query: {}, headers: {}, endpoint:, method: :get, body: nil)
      url = URI.escape(base_url + endpoint)
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

    def check_for_error(response_body:, code:)
      case code
      when 200 # rubocop:disable Lint/EmptyWhen
      when 400
        fail Caseflow::Error::VaDotGovRequestError, code: code, message: response_body
      when 500
        fail Caseflow::Error::VaDotGovServerError, code: code, message: response_body
      else
        msg = "Error: #{response_body}, HTTP code: #{code}"
        fail Caseflow::Error::VaDotGovServerError, code: code, message: msg
      end
    end
    # :nocov:
  end
end
