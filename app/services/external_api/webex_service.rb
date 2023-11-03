# frozen_string_literal: true

require "json"

class ExternalApi::WebexService
  BASE_URL = "#{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}"
  AUTH_URL = "/v1/access_token"
  GRANT_TYPE = "refresh_token"
  CLIENT_ID = ENV["WEBEX_CLIENT_ID"]
  CLIENT_SECRET = ENV["WEBEX_CLIENT_SECRET"]
  REFRESH_TOKEN = ENV["WEBEX_REFRESH_TOKEN"]
  HEADERS = {
    "Content-Type": "application/x-www-form-urlencoded", Accept: "application/json"
  }.freeze

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
    url = URI::DEFAULT_PARSER.escape(BASE_URL + AUTH_URL)
    params = {
      grant_type: GRANT_TYPE,
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      refresh_token: REFRESH_TOKEN
    }
    encoded_params = URI.encode_www_form(params)
    response = Faraday.post(url, encoded_params)
    caseflow_res = ExternalApi::WebexService::Response.new(response)
    caseflow_res.resp unless caseflow_res.error
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
