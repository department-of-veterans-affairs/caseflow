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
        "nbf": virtual_hearing.hearing.scheduled_for.beginning_of_day.to_i,
        "exp": virtual_hearing.hearing.scheduled_for.end_of_day.to_i
      },
      "aud": @aud,
      "numGuest": 1,
      "numHost": 2,
      "provideShortUrls": true,
      "verticalType": "gen"
    }
    resp = send_webex_request(body: body, method: "POST")
    return if resp.nil?

    ExternalApi::WebexService::CreateResponse.new(resp)
  end

  def delete_conference(virtual_hearing)
    body = {
      "jwt": {
        "sub": virtual_hearing.subject_for_conference,
        "nbf": 0,
        "exp": 0
      },
      "aud": @aud,
      "numGuest": 1,
      "numHost": 2,
      "provideShortUrls": true,
      "verticalType": "gen"
    }
    resp = send_webex_request(body: body, method: "POST")
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
      refresh_token: CredStash.get("webex_#{Rails.deploy_env}_refresh_token")
    }

    headers = {
      "Content-Type" => "application/x-www-form-urlencoded",
      "Accept" => "application/json",
      "Authorization" => CredStash.get("webex_#{Rails.deploy_env}_access_token")
    }

    request = HTTPI::Request.new
    request.url = url
    request.body = URI.encode_www_form(body)
    request.headers = headers

    response = HTTPI.post(request)

    ExternalApi::WebexService::AccessTokenRefreshResponse.new(response)
  end

  def get_recordings_list
    body = nil
    method = "GET"
    resp = send_webex_request(body: body, method: method)
    ExternalApi::WebexService::RecordingsListResponse.new(resp) if !resp.nil?
  end

  def get_recording_details
    body = nil
    method = "GET"
    resp = send_webex_request(body: body, method: method)
    ExternalApi::WebexService::RecordingDetailsResponse.new(resp) if !resp.nil?
  end

  private

  def send_webex_request(body: nil, method: nil)  # Added method argument with a default value
    url = "https://#{@host}#{@domain}#{@api_endpoint}"
    request = HTTPI::Request.new(url)
    request.open_timeout = 300
    request.read_timeout = 300
    request.body = body.to_json unless body.nil?
    request.headers["Authorization"] = "Bearer #{@apikey}"
    request.method = method.downcase.to_sym  # This line sets the method on the HTTPI request

    MetricsService.record(
      "#{@host} #{method} request to #{url}",
      service: :webex,
      name: @api_endpoint
    ) do
      HTTPI.request(method.downcase.to_sym, request)
    end
  end
end
