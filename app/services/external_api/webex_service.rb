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

  def create_conference(conferenced_item)
    body = {
      "jwt": {
        "sub": conferenced_item.subject_for_conference,
        "nbf": conferenced_item.nbf,
        "exp": conferenced_item.exp
      },
      "aud": @aud,
      "numHost": 2,
      "provideShortUrls": true,
      "verticalType": "gen"
    }

    resp = send_webex_request(body)
    return if resp.nil?

    ExternalApi::WebexService::CreateResponse.new(resp)
  end

  def delete_conference(conferenced_item)
    body = {
      "jwt": {
        "sub": conferenced_item.subject_for_conference,
        "nbf": 0,
        "exp": 0
      },
      "aud": @aud,
      "numHost": 2,
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
