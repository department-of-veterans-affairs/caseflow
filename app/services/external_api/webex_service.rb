# frozen_string_literal: true

# This file defines the ExternalApi::WebexService class, which is responsible for interacting
# with the Webex API. This service is used for creating and deleting conferences, refreshing
# access tokens, and fetching recording details.
#
# Key behaviors include:
# 1. The initialize method sets up the service with necessary parameters like host, port, aud,
#    apikey, domain, api_endpoint, and query.
# 2. The create_conference method sends a POST request to the Webex API to create a new conference.
# 3. The delete_conference method sends a POST request to the Webex API to delete a conference.
# 4. The refresh_access_token method sends a POST request to the Webex API to refresh the access token.
# 5. The fetch_recordings_list method sends a GET request to the Webex API to fetch a list of recordings.
# 6. The fetch_recording_details method sends a GET request to the Webex API to fetch details of a recording.
# 7. The send_webex_request method is a private method used to send requests to the Webex API
#    with the specified body and method.
#
# All requests to the Webex API are recorded using the MetricsService.

require "json"

class ExternalApi::WebexService
  BASE_URL = "https://#{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}"

  # rubocop:disable Metrics/ParameterLists
  def initialize(host:, port:, aud:, apikey:, domain:, api_endpoint:, query:)
    @host = host
    @port = port
    @aud = aud
    @apikey = apikey
    @domain = domain
    @api_endpoint = api_endpoint
    @query = query
  end
  # rubocop:enable Metrics/ParameterLists

  def create_conference(hearing)
    body = {
      "jwt": {
        "sub": hearing.subject_for_conference,
        "nbf": hearing.hearing.scheduled_for.beginning_of_day.to_i,
        "exp": hearing.hearing.scheduled_for.end_of_day.to_i
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

  def delete_conference(hearing)
    body = {
      "jwt": {
        "sub": hearing.subject_for_conference,
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

  def fetch_recordings_list
    body = nil
    method = "GET"
    resp = send_webex_request(body: body, method: method)
    ExternalApi::WebexService::RecordingsListResponse.new(resp) if !resp.nil?
  end

  def fetch_recording_details
    body = nil
    method = "GET"
    resp = send_webex_request(body: body, method: method)
    ExternalApi::WebexService::RecordingDetailsResponse.new(resp) if !resp.nil?
  end

  private

  def send_webex_request(body: nil, method: nil)
    url = "https://#{@host}#{@domain}#{@api_endpoint}"
    request = HTTPI::Request.new(url)
    request.open_timeout = 300
    request.read_timeout = 300
    request.body = body.to_json unless body.nil?
    request.headers["Authorization"] = "Bearer #{@apikey}"
    request.method = method.downcase.to_sym

    MetricsService.record(
      "#{@host} #{method} request to #{url}",
      service: :webex,
      name: @api_endpoint
    ) do
      HTTPI.request(method.downcase.to_sym, request)
    end
  end
end
