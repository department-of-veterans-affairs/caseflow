# frozen_string_literal: true

require "json"
require "rcredstash"

class ExternalApi::WebexService
  BASE_URL = "https://#{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}"

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
        "Nbf": virtual_hearing.hearing.scheduled_for.beginning_of_day.to_i,
        "Exp": virtual_hearing.hearing.scheduled_for.end_of_day.to_i
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
      "provideShortUrls": true
    }
    resp = send_webex_request(body: body)
    return if resp.nil?

    ExternalApi::WebexService::DeleteResponse.new(resp)
  end

  # Purpose: Refreshing the access token to access the API
  # Return: The response body
  def refresh_access_token
    url = URI::DEFAULT_PARSER.escape("#{BASE_URL}/v1/access_token")

    body = {
      grant_type: "refresh_token",
      client_id: ENV["WEBEX_CLIENT_ID"],
      client_secret: ENV["WEBEX_CLIENT_SECRET"],
      refresh_token: CredStash.get(:webex_refresh_token)
    }

    headers = {
      "Content-Type" => "application/x-www-form-urlencoded",
      "Accept" => "application/json",
      "Authorization" => CredStash.get(:webex_access_token)
    }

    request = HTTPI::Request.new
    request.url = url
    request.body = URI.encode_www_form(body)
    request.headers = headers

    response = HTTPI.post(request)

    ExternalApi::WebexService::AccessTokenRefreshResponse.new(response)
  end

  private

  # :nocov:
  def send_webex_request(body: nil)
    url = "https://#{@host}#{@domain}#{@api_endpoint}"
    request = HTTPI::Request.new(url)
    request.open_timeout = 300
    request.read_timeout = 300
    request.body = body.to_json unless body.nil?
    request.headers["Authorization"] = "Bearer #{@apikey}"
    MetricsService.record(
      "#{@host} POST request to #{url}",
      service: :webex,
      name: @api_endpoint
    ) do
      HTTPI.post(request)
    end
  end
end
