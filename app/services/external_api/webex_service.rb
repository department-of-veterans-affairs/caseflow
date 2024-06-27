# frozen_string_literal: true

require "json"

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
class ExternalApi::WebexService
  # rubocop:disable Metrics/ParameterLists
  def initialize(host:, port:, aud:, apikey:, domain:, api_endpoint:, query: nil)
    @host = host
    @port = port
    @aud = aud
    @apikey = apikey
    @domain = domain
    @api_endpoint = api_endpoint
    @query = query
  end
  # rubocop:enable Metrics/ParameterLists

  def self.access_token
    CredStash.get("webex_#{Rails.deploy_env}_access_token")
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
    method = "POST"
    ExternalApi::WebexService::CreateResponse.new(send_webex_request(body, method))
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
    method = "POST"
    ExternalApi::WebexService::DeleteResponse.new(send_webex_request(body, method))
  end

  # Purpose: Refreshing the access token to access the API
  # Return: The response body
  def refresh_access_token
    url = URI::DEFAULT_PARSER.escape("https://#{@host}#{@domain}#{@api_endpoint}access_token")

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
    @api_endpoint += "admin/recordings"
    ExternalApi::WebexService::RecordingsListResponse.new(send_webex_request(body, method))
  end

  def fetch_recording_details(recording_id)
    body = nil
    method = "GET"
    @api_endpoint += "recordings/#{recording_id}"
    ExternalApi::WebexService::RecordingDetailsResponse.new(send_webex_request(body, method))
  end

  def fetch_rooms_list
    body = nil
    method = "GET"
    @api_endpoint += "rooms"
    ExternalApi::WebexService::RoomsListResponse.new(send_webex_request(body, method))
  end

  def fetch_room_details(room_id)
    body = nil
    method = "GET"
    @api_endpoint += "rooms/#{room_id}/meetingInfo"
    ExternalApi::WebexService::RoomDetailsResponse.new(send_webex_request(body, method))
  end

  private

  # :nocov:
  # rubocop:disable Metrics/MethodLength
  def send_webex_request(body, method)
    url = "https://#{@host}#{@domain}#{@api_endpoint}"
    request = HTTPI::Request.new(url)
    request.open_timeout = 300
    request.read_timeout = 300
    request.body = body.to_json unless body.nil?
    request.query = @query
    request.headers = { "Authorization": "Bearer #{@apikey}", "Content-Type": "application/json" }

    MetricsService.record(
      "#{@host} #{method} request to #{url}",
      service: :webex,
      name: @api_endpoint
    ) do
      case method
      when "POST"
        response = HTTPI.post(request)
        fail ExternalApi::WebexService::Response.new(response).error if response.error?

        response
      when "GET"
        response = HTTPI.get(request)
        fail ExternalApi::WebexService::Response.new(response).error if response.error?

        response
      else
        fail NotImplementedError
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
  # :nocov:
end
