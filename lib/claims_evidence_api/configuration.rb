# frozen_string_literal: true

module ClaimsEvidenceApi
  class Configuration < Common::Client::Configuration::REST
    self.read_timeout = Settings.scorecard.read_timeout || read_timeout
    self.open_timeout = Settings.scorecard.open_timeout || open_timeout

    def base_path
      "#{Settings.scorecard.url}/"
    end

    def service_name
      'ClaimsEvidence'
    end

    def connection
      Faraday.new(base_path, headers: base_request_headers, request: request_options) do |conn|
        conn.request :json

        conn.response :snakecase
        conn.response :raise_error, error_prefix: service_name
        conn.response :claims_evidence_api_errors
        conn.response :json_parser

        conn.adapter Faraday.default_adapter
      end
    end
  end
end
