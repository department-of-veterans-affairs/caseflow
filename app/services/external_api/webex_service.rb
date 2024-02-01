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

    resp = send_webex_request(body)
    # resp = send_webex_request(body)
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
    resp = send_webex_request(body)
    # resp = send_webex_request(body: body)
    return if resp.nil?

    ExternalApi::WebexService::DeleteResponse.new(resp)
  end

  def get_recordings_list
    resp = send_webex_request(method: :get)
    return if resp.nil?

    ExternalApi::WebexService::RecordingsListResponse.new(resp)
  end

  private

  # :nocov:
  def send_webex_request(body = nil)
  # def send_webex_request(body: body, method: :post)

    url = "https://#{@host}#{@domain}#{@api_endpoint}"
    request = HTTPI::Request.new(url)
    request.open_timeout = 300
    request.read_timeout = 300
    request.body = body.to_json unless body.nil?
    request.query = @query
    request.headers = { "Authorization": "Bearer #{@apikey}", "Content-Type": "application/json" }

    MetricsService.record(
      "#{@host} #{method.to_s_upcase} request to #{url}",
      service: :webex,
      name: @api_endpoint
    ) do
      case method
      when :post
        HTTPI.post(request)
      when :get
        HTTPI.get(request)
      end
    end
  end
  # :nocov:
end
