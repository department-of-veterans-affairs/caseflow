# frozen_string_literal: true

class ExternalApi::ClaimEvidenceService
  JWT_TOKEN = ENV["CLAIM_EVIDENCE_JWT_TOKEN"]
  BASE_URL = ENV["CLAIM_EVIDENCE_API_URL"]
  SERVER = "/api/v1/rest"
  DOCUMENT_TYPES_ENDPOINT = "/documenttypes"
  HEADERS = {
    "Content-Type": "application/json", Accept: "application/json"
  }.freeze

  class << self

    def document_types_request
      {
        headers: HEADERS,
        endpoint: DOCUMENT_TYPES_ENDPOINT,
        method: :get
      }
    end

    def document_types
      send_ce_api_request(document_types_request).body["documentTypes"]
    end

    def alt_document_types
      send_ce_api_request(document_types_request).body["alternativeDocumentTypes"]
    end

    def send_ce_api_request(query: {}, headers: {}, endpoint:, method: :get, body: nil)
      url = URI.escape(BASE_URL + SERVER + endpoint)
      request = HTTPI::Request.new(url)
      request.query = query
      request.open_timeout = 30
      request.read_timeout = 30
      request.body = body.to_json unless body.nil?
      request.auth.ssl.ssl_version  = :TLSv1_2
      request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]
      request.headers = headers.merge(Authorization: "Bearer " + JWT_TOKEN)

      sleep 1
      MetricsService.record("api.notifications.claim.evidence #{method.to_s.upcase} request to #{url}",
                            service: :claim_evidence,
                            name: endpoint) do
        case method
        when :get
          response = HTTPI.get(request)
          service_response = ExternalApi::ClaimEvidenceService::Response.new(response)
          fail service_response.error if service_response.error.present?

          service_response
        else
          fail NotImplementedError
        end
      end
    end
  end
end
