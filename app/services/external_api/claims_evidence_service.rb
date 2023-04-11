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

  def generate_token
    ExternalApi::JwtToken.generate_token(Settings., TOKEN_ALG, SERVICE_ID)
  end

  def conn
    url = URI.escape(BASE_URL + endpoint)
    request = HTTPI::Request.new(url)
    request.query = query
    request.open_timeout = 30
    request.read_timeout = 30
    request.body = body.to_json unless body.nil?
    request.auth.ssl.ssl_version  = :TLSv1_2
    request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]
    request.headers = headers.merge(Authorization: "Bearer " + generate_token)
  end
end
