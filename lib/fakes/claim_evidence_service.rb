# frozen_string_literal: true


class Fakes::ClaimEvidenceService
  JWT_TOKEN = ENV["CLAIM_EVIDENCE_JWT_TOKEN"]
  BASE_URL = ENV["CLAIM_EVIDENCE_API_URL"]
  SERVER = "/api/v1/rest"
  DOCUMENT_TYPES_ENDPOINT = "/documenttypes"
  HTTP_PROXY = ENV["DEVVPN_PROXY"]
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
      response = if HTTP_PROXY
        use_faraday(document_types_request)
      else
        JSON.parse(IO.binread(File.join(Rails.root, "lib", "fakes", "data", "DOCUMENT_TYPES.json")))
      end

      response.body["documentTypes"]
    end

    def alt_document_types
      response = if HTTP_PROXY
        use_faraday(document_types_request)
      else
        JSON.parse(IO.binread(File.join(Rails.root, "lib", "fakes", "data", "DOCUMENT_TYPES.json")))
      end

      response.body["alternativeDocumentTypes"]
    end

    def use_faraday(query: {}, headers: {}, endpoint:, method: :get, body: nil)
      url = URI.escape(BASE_URL)
      client_cert = OpenSSL::X509::Certificate.new(File.read(ENV["SSL_CERT_FILE"]))
      client_key = OpenSSL::PKey::RSA.new(File.read(ENV["CLAIM_EVIDENCE_KEY_FILE"]), ENV["CLAIM_EVIDENCE_KEY_PASSPHRASE"])
      conn = Faraday.new(
        url: url,
        headers: headers.merge(Authorization: "Bearer " + JWT_TOKEN),
        proxy: HTTP_PROXY,
        ssl: {
          client_cert: client_cert,
          client_key: client_key,
          verify: !ApplicationController.dependencies_faked?
        }
      ) do |c|
        c.response :json
        c.adapter Faraday.default_adapter
      end

      sleep 1
      MetricsService.record("api.notifications.claim.evidence #{method.to_s.upcase} request to #{url}",
                            service: :claim_evidence,
                            name: endpoint) do
        case method
        when :get
          response = conn.get(SERVER + endpoint, query)
          service_response = ExternalApi::ClaimEvidenceService::Response.new(response)
          fail service_response.error if service_response.error.present?

          service_response
        when :post
          response = conn.post(SERVER + endpoint, body)
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
