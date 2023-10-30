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
        "Nbf": virtual_hearing.hearing.scheduled_for.beginning_of_day.to_i,
        "Exp": virtual_hearing.hearing.scheduled_for.end_of_day.to_i
      },
      "aud": aud,
      "numGuest": 1,
      "numHost": 1,
      "provideShortUrls": true
    }

    resp = send_webex_request(api_endpoint, :post, body: body)
    return if resp.nil?

    ExternalApi::WebexService::CreateResponse.new(resp)
  end

  # won't even need this method at all
  def delete_conference(virtual_hearing)
    return if virtual_hearing.conference_id.nil?

    delete_endpoint = "#{api_endpoint}#{conference_id}/"
    resp = send_webex_request(delete_endpoint, :delete)
    return if resp.nil?

    ExternalApi::WebexService::DeleteResponse.new(resp)
  end

  private

  # :nocov:
  def send_webex_request(endpoint, method, body: nil)
    url = "http://#{host}:#{port}/#{endpoint}"
    request = HTTPI::Request.new(url)
    request.open_timeout = 300
    request.read_timeout = 300
    request.body = body.to_json unless body.nil?

    request.headers["Content-Type"] = "application/json" if method == :post

    MetricsService.record(
      "#{host} #{method.to_s.upcase} request to #{url}",
      service: :webex,
      name: endpoint
    ) do
      case method
      when :delete
        HTTPI.delete(request)
      when :post
        HTTPI.post(request)
      end
    end
  end
  # :nocov:
end
