# frozen_string_literal: true

require "json"

class ExternalApi::WebexService
  def initialize(host:, port:, aud:, apikey:, domain:, api_endpoint:)
    @host = host
    @port = port
    @aud = aud
    @apikey = apikey
    @domain = domain
    @api_endpoint = api_endpoint
  end

  def create_conference(virtual_hearing)
    body = {
      "jwt": {
        "sub": virtual_hearing.subject_for_conference,
        "Nbf": virtual_hearing.nbf,
        "Exp": virtual_hearing.exp
      },
      "aud": @aud,
      "numGuest": 1,
      "numHost": 1,
      "provideShortUrls": true
    }

    resp = send_webex_request(body: body)
    return if resp.nil?

    ExternalApi::WebexService::CreateResponse.new(resp)
  end

  def delete_conference(virtual_hearing)
    body = {
      "jwt": {
        "sub": virtual_hearing.subject_for_conference,
        "Nbf": 0,
        "Exp": 0
      },
      "aud": @aud,
      "numGuest": 1,
      "numHost": 1,
      "provideShortUrls": true,
      "verticalType": "gen"
    }
    resp = send_webex_request(body)
    return if resp.nil?

    ExternalApi::WebexService::DeleteResponse.new(resp)
  end

  private

  # :nocov:
  def send_webex_request(body = nil)
    url = "https://#{@host}#{@domain}#{@api_endpoint}"
    request = HTTPI::Request.new(url)
    request.open_timeout = 300
    request.read_timeout = 300
    request.body = body.to_json unless body.nil?

    request.headers = { "Authorization": "Bearer #{@apikey}", "Content-Type": "application/json" }

    MetricsService.record(
      "#{@host} POST request to #{url}",
      service: :webex,
      name: @api_endpoint
    ) do
      HTTPI.post(request)
    end
  end
  # :nocov:
end
