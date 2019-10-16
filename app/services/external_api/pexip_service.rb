# frozen_string_literal: true

require "json"

class ExternalApi::PexipService
  CONFERENCES_ENDPOINT = "api/admin/configuration/v1/conference/"

  def initialize(host:, port: 443, user_name:, password:, client_host:)
    @host = host
    @port = port
    @user_name = user_name
    @password = password
    @client_host = client_host
  end

  def create_conference(host_pin, guest_pin, name)
    body = {
      "aliases": [{ "alias": name.to_s }, { "alias": "BVA#{name}" }, { "alias": "BVA#{name}.#{client_host}" }],
      "allow_guests": true,
      "description": "Created by Caseflow",
      "enable_chat": "yes",
      "enable_overlay_text": true,
      "force_presenter_into_main": true,
      "guest_pin": guest_pin.to_s,
      "name": "BVA#{name}",
      "pin": host_pin.to_s,
      "tag": "CASEFLOW"
    }
    # send_pexip_request(CONFERENCES_ENDPOINT, :post, body: body)
    resp = send_pexip_request(CONFERENCES_ENDPOINT, :post, body: body)
    return if resp.nil?

    check_for_error(resp)

    {
      "conference_id": resp.headers["Location"].split('/')[-1] || nil
    }
  end

  def delete_conference(conference_id)
    delete_endpoint = "#{CONFERENCES_ENDPOINT}#{conference_id}/"
    # send_pexip_request(delete_endpoint, :delete)
    resp = send_pexip_request(delete_endpoint, :delete)
    return if resp.nil?

    check_for_error(resp)
  end

  private

  attr_reader :host, :port, :user_name, :password, :client_host

  def send_pexip_request(endpoint, method, body: nil)
    url = "https://#{host}:#{port}/#{endpoint}"
    request = HTTPI::Request.new(url)
    request.auth.basic(user_name, password)
    request.open_timeout = 30
    request.read_timeout = 30
    request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]
    request.body = body.to_json unless body.nil?

    request.headers["Content-Type"] = "application/json" if method == :post

    MetricsService.record("#{host} #{method.to_s.upcase} request to #{url}",
                            service: :pexip,
                            name: endpoint) do
      case method
        when :delete
          HTTPI.delete(request)
        when :post
          HTTPI.post(request)
        end
      end
  end

  def check_for_error(resp)
    return if !resp.error?

    msg = error_message(resp)

    case resp.code
    when 400
      fail Caseflow::Error::PexipBadRequestError, code: resp.code, message: msg
    when 501
      fail Caseflow::Error::PexipAPIError, code: resp.code, message: msg
    when 404
      fail Caseflow::Error::PexipNotFoundError, code: resp.code, message: msg
    when 405
      fail Caseflow::Error::PexipMethodNotAllowedError, code: resp.code, message: msg
    else
      fail Caseflow::Error::PexipAPIError, code: resp.code, message: msg
    end
  end

  def error_message(resp)
    if !resp.raw_body.nil? && resp.headers["Content-Type"] == "application/json"
      JSON.parse(resp.raw_body)["conference"]["name"]
    else
      ""
    end
  end
end
