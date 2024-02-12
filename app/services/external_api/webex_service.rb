# frozen_string_literal: true

require "json"

class ExternalApi::WebexService
  def initialize(host:, port:, aud:, apikey:, domain:, api_endpoint:, query:)
    @host = host
    @port = port
    @aud = aud
    @apikey = apikey
    @domain = domain
    @api_endpoint = api_endpoint
    @query = query
  end

  def create_conference(conferenced_item)
    body = {
      "jwt": {
        "sub": conferenced_item.subject_for_conference,
        "nbf": conferenced_item.nbf,
        "exp": conferenced_item.exp
      },
      "aud": @aud,
      "numHost": 1,
      "provideShortUrls": true,
      "verticalType": "gen"
    }

    method = "POST"

    resp = send_webex_request(body, method)
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
      "numHost": 1,
      "provideShortUrls": true,
      "verticalType": "gen"
    }

    method = "POST"

    resp = send_webex_request(body, method)
    return if resp.nil?

    ExternalApi::WebexService::DeleteResponse.new(resp)
  end

  def get_recordings_list
    body = nil
    method = "GET"
    resp = send_webex_request(body, method)
    return if resp.nil?

    ExternalApi::WebexService::RecordingsListResponse.new(resp)
  end

  def get_recording_details
    body = nil
    method = "GET"
    resp = send_webex_request(body, method)
    return if resp.nil?

    ExternalApi::WebexService::RecordingDetailsResponse.new(resp)
  end

  private

  # :nocov:
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
        HTTPI.post(request)
      when "GET"
        HTTPI.get(request)
      end
    end
  end
  # :nocov:
end
