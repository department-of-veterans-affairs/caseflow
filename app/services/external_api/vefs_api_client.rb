# frozen_string_literal: true

require "httparty"

class ExternalApi::VefsApiClient
  include HTTParty

  base_uri ENV["VEFS_API_BASE_URL"]
  raise_on ["4[0-9]*", "5[0-9]*"] # Will raise exception if HTTP response code is in matching range

  def fetch_cmp_document_content_by_uuid(cmp_document_uuid)
    response = nil
    doc_content = nil

    MetricsService.record(
      "Fetch content for CMP document with UUID #{cmp_document_uuid}",
      service: :vefs_api_client,
      name: "fetch_cmp_document_content_by_uuid"
    ) do
      response = do_api_request(
        endpoint: "/api/v1/rest/files/#{cmp_document_uuid}/content",
        method: :get
      )
    end

    if response.present? && response.success?
      doc_content = response.body
    end

    doc_content
  end

  private

  def do_api_request(endpoint:, method:, params: {}, headers: {})
    response = nil

    begin
      case method
      when :get
        response = self.class.get(
          endpoint,
          headers: bearer_token_header.merge!(headers),
          query: params
        )
      else
        fail "Unsupported HTTP method: #{method}"
      end
    rescue HTTParty::ResponseError => error
      Rails.logger.error(error)
      vefs_error_handler.handle_error(error: error, error_details: {})
    end

    response
  end

  def vefs_error_handler
    @vefs_error_handler ||= ErrorHandlers::VefsApiErrorHandler.new
  end

  def bearer_token_header
    {
      "Authorization": "Bearer #{bearer_token}"
    }
  end

  def bearer_token
    @bearer_token ||= if Rails.in_upper_env?
                        generate_bearer_token
                      else
                        fetch_bearer_token
                      end
  end

  def generate_bearer_token
    # TODO: Update to generate a bearer token
    fetch_bearer_token
  end

  def fetch_bearer_token
    fetched_token = nil

    response = self.class.post(
      "/api/v1/rest/api/v1/token",
      body: bearer_token_request_json_body,
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "text/plain"
      }
    )

    if response.present? && response.success?
      fetched_token = response.body
    end

    fetched_token
  end

  # rubocop:disable Metrics/MethodLength
  def bearer_token_request_json_body
    {
      "applicationID": "ShareUI",
      "appToken": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9",
      "assuranceLevel": 2,
      "birthDate": "1978-05-20",
      "correlationIds": [
        "77779102^NI^200M^USVHA^P",
        "912444689^PI^200BRLS^USVBA^A",
        "6666345^PI^200CORP^USVBA^A",
        "1105051936^NI^200DOD^USDOD^A",
        "912444689^SS"
      ],
      "email": "jane.doe@va.gov",
      "firstName": "JANE",
      "gender": "FEMALE",
      "lastName": "DOE",
      "middleName": "M",
      "prefix": "Ms",
      "stationID": "310",
      "suffix": "S",
      "userID": "vhaislXXXXX"
    }.to_json
  end
  # rubocop:enable Metrics/MethodLength
end
