# frozen_string_literal: true

require "json"

class ExternalApi::WebexService
  def initialize(config:)
    @config = config
  end

  def create_conference(conferenced_item)
    body = {
      "jwt": {
        "sub": conferenced_item.subject_for_conference,
        "nbf": conferenced_item.nbf,
        "exp": conferenced_item.exp
      },
      "aud": @config[:aud],
      "numHost": 2,
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
      "aud": @config[:aud],
      "numHost": 2,
      "provideShortUrls": true,
      "verticalType": "gen"
    }

    method = "POST"

    resp = send_webex_request(body, method)
    return if resp.nil?

    ExternalApi::WebexService::DeleteResponse.new(resp)
  end

  def fetch_recordings_list
    body = nil
    method = "GET"
    resp = send_webex_request(body, method)
    return if resp.nil?

    ExternalApi::WebexService::RecordingsListResponse.new(resp)
  end

  def fetch_recording_details
    body = nil
    method = "GET"
    resp = send_webex_request(body, method)
    return if resp.nil?

    ExternalApi::WebexService::RecordingDetailsResponse.new(resp)
  end

  private

  # :nocov:
  def send_webex_request(body, method)
    url = "https://#{@config[:host]}#{@config[:domain]}#{@config[:api_endpoint]}"
    request = HTTPI::Request.new(url)
    request.open_timeout = 300
    request.read_timeout = 300
    request.body = body.to_json unless body.nil?
    request.query = @config[:query]
    request.headers = { "Authorization": "Bearer #{@config[:apikey]}", "Content-Type": "application/json" }

    MetricsService.record(
      "#{@config[:host]} #{method} request to #{url}",
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
