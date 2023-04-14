# frozen_string_literal: true

# :nocov:
class ClaimsEvidenceCaseflowLogger
  def log(event, data)
    case event
    when :request
      status = data[:response_code]

      if status != 200
        Rails.logger.error(
          "ClaimsEvidence HTTP Error #{status} (#{data.pretty_inspect})"
        )
      else
        Rails.logger.info(
          "ClaimsEvidence HTTP Success #{status} (#{data.pretty_inspect})"
        )
      end
    end
  end
end
# :nocov:

class ExternalApi::ClaimsEvidenceService
  SERVICE_ID = ENV["CLAIM_EVIDENCE_SERVICE_ID"]
  TOKEN_ALG = ENV["CLAIM_EVIDENCE_TOKEN_ALG"]
  JWT_JTI = ENV["CLAIM_EVIDENCE_JWT_JTI"]
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
      send_ce_api_request(document_types_request)["documentTypes"]
    end

    def alt_document_types
      send_ce_api_request(document_types_request)["alternativeDocumentTypes"]
    end

    def generate_token
      payload = {
        jti: JWT_JTI,
        applicationID: SERVICE_ID
      }
      ExternalApi::JwtToken.generate_token(ENV["SSL_CERT_FILE"], TOKEN_ALG, SERVICE_ID)
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
      request.headers = headers.merge(Authorization: "Bearer " + generate_token)

      sleep 1
      MetricsService.record("api.notifications.claims.evidence #{method.to_s.upcase} request to #{url}",
                            service: :claims_evidence,
                            name: endpoint) do
        case method
        when :get
          response = HTTPI.get(request)
          service_response = ExternalApi::VANotifyService::Response.new(response)
          fail service_response.error if service_response.error.present?

          service_response
        when :post
          response = HTTPI.post(request)
          service_response = ExternalApi::VANotifyService::Response.new(response)
          fail service_response.error if service_response.error.present?

          service_response
        else
          fail NotImplementedError
        end
      end
    end
  end
end
