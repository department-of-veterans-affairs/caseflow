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

  # :reek:FeatureEnvy
  def create_conference(virtual_hearing)
    host_pin = virtual_hearing.host_pin
    guest_pin = virtual_hearing.guest_pin
    name = virtual_hearing.alias

    body = {
      "aliases": [{ "alias": "BVA#{name}" }, { "alias": VirtualHearing.formatted_alias(name) }, { "alias": name }],
      "allow_guests": true,
      "description": "Created by Caseflow",
      "enable_chat": "yes",
      "enable_overlay_text": true,
      # Theme ID is hard coded for now because it's the same in both environments.
      "ivr_theme": "/api/admin/configuration/v1/ivr_theme/13/",
      "force_presenter_into_main": true,
      "guest_pin": guest_pin.to_s,
      "name": "BVA#{name}",
      "pin": host_pin.to_s,
      "tag": "CASEFLOW"
    }

    resp = send_pexip_request(CONFERENCES_ENDPOINT, :post, body: body)
    return if resp.nil?

    ExternalApi::PexipService::CreateResponse.new(resp)
  end

  def delete_conference(virtual_hearing)
    if virtual_hearing.conference_id.nil?
      return ExternalApi::PexipService::DeleteResponse.new(not_found_response)
    end

    delete_endpoint = "#{CONFERENCES_ENDPOINT}#{virtual_hearing.conference_id}/"
    resp = send_pexip_request(delete_endpoint, :delete)
    return lack_of_connectivity_response if resp.nil?

    ExternalApi::PexipService::DeleteResponse.new(resp)
  end

  def not_found_response
    HTTPI::Response.new(404, {}, {})
  end

  private

  def lack_of_connectivity_response
    HTTPI::Response.new(503, {}, {})
  end

  attr_reader :host, :port, :user_name, :password, :client_host

  # :nocov:
  def send_pexip_request(endpoint, method, body: nil)
    url = "https://#{host}:#{port}/#{endpoint}"
    request = HTTPI::Request.new(url)
    request.auth.basic(user_name, password)
    request.open_timeout = 300
    request.read_timeout = 300
    request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]
    request.body = body.to_json unless body.nil?

    request.headers["Content-Type"] = "application/json" if method == :post

    MetricsService.record(
      "#{host} #{method.to_s.upcase} request to #{url}",
      service: :pexip,
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
