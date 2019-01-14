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

      track_pages(page)

      facility_results
    end

    # rubocop:disable Metrics/ParameterLists
    def validate_address(
        address_line1:, address_line2: nil,
        address_line3: nil, city:, state:, zip_code:, country:
      )
      # rubocop:enable Metrics/ParameterLists
      response = send_va_dot_gov_request(
        body: validate_request_body(
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

      validated_address_json(resp_body)
    end

    def full_address(address_1:, address_2: nil, address_3: nil)
      address_line1 = address_1
      address_line2 = address_2.blank? ? "" : " " + address_2
      address_line3 = address_3.blank? ? "" : " " + address_3

      "#{address_line1}#{address_line2}#{address_line3}"
    end

    private

    def base_url
      ENV["VA_DOT_GOV_API_URL"] || ""
    end

    def facilities_endpoint
      "services/va_facilities/v0/facilities"
    end

    def address_validation_endpoint
      "services/address_validation/v1/validate"
    end

    # rubocop:disable Metrics/ParameterLists
    def validate_request_body(
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

    def validated_address_json(resp_body)
      {
        lat: resp_body["geocode"]["latitude"],
        long: resp_body["geocode"]["longitude"],
        city: resp_body["address"]["city"],
        full_address: full_address(
          address_1: resp_body["address"]["addressLine1"],
          address_2: resp_body["address"]["addressLine2"],
          address_3: resp_body["address"]["addressLine3"]
        ),
        country_code: resp_body["address"]["country"]["fipsCode"],
        state_code: resp_body["address"]["stateProvince"]["code"],
        zip_code: resp_body["address"]["zipCode5"]
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
        address: full_address(
          address_1: attrs["address"]["physical"]["address_1"],
          address_2: attrs["address"]["physical"]["address_2"],
          address_3: attrs["address"]["physical"]["address_3"]
        ),
        city: attrs["address"]["physical"]["city"],
        state: attrs["address"]["physical"]["state"],
        zip_code: attrs["address"]["physical"]["zip"],
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
