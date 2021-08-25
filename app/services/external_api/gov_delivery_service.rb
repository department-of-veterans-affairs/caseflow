# frozen_string_literal: true

require "json"

class ExternalApi::GovDeliveryService
  BASE_URL = ENV["GOVDELIVERY_SERVER"]
  AUTH_TOKEN = ENV["GOVDELIVERY_TOKEN"]
  CERT_FILE_LOCATION = ENV["SSL_CERT_FILE"]

  class << self
    def get_message_status(email_event:)
      # Construct the endpoint from the email event
      path = "#{email_event.external_message_id}/recipients"

      # Send the request to the gov delivery API
      response = send_gov_delivery_request(path, :get)
      return if response.nil?

      # Return the GovDelivery Response
      recipients = ExternalApi::GovDeliveryService::Response.new(response)

      # There will only ever be one recipient for the emails we're sending
      recipients.body.status
    end
  end

  def create_webhook(external_message_id:, event_type:)
    body = {
      "url": "",
      "event_type": event_type
    }

    # Send the API request
    response = send_gov_delivery_request("/webhooks", :post, body: body)
    return if response.nil?

    # Return the GovDelivery Create Response
    ExternalApi::GovDeliveryService::CreateResponse.new(response)
  end

  def delete_webhook(webhook_id:)
    # Send the request to the gov delivery API
    response = send_gov_delivery_request("/webhooks/#{webhook_id}", :delete)
    return if response.nil?

    # Return the GovDelivery Response
    ExternalApi::GovDeliveryService::DeleteResponse.new(response)
  end

  def list_all_webhooks
    # Send the request to the gov delivery API
    response = send_gov_delivery_request("/webhooks", :get)
    return if response.nil?

    # Return the GovDelivery Response
    ExternalApi::GovDeliveryService::Response.new(response)
  end

  private

  # :nocov:
  def send_gov_delivery_request(endpoint, method, body: nil)
    url = URI::DEFAULT_PARSER.escape("https://#{BASE_URL}#{endpoint}")

    # Create the API request
    request = create_gov_delivery_request(url)

    # Attach the body and optional headers if present
    request.body = body.to_json unless body.nil?
    request.headers["Content-Type"] = "application/json" if method == :post

    MetricsService.record(
      "#{host} #{method.to_s.upcase} request to #{url}",
      service: :gov_delivery,
      name: endpoint
    ) do
      case method
      when :get
        HTTPI.get(request)
      when :delete
        HTTPI.delete(request)
      when :post
        HTTPI.post(request)
      end
    end
  end

  def create_gov_delivery_request(url)
    # Create the AI request
    request = HTTPI::Request.new(url)

    # Attach the auth tokena dn SSL file
    request.auth.ssl.ca_cert_file = CERT_FILE_LOCATION
    request.headers = { "X-Auth-Token": AUTH_TOKEN }

    # Set the request timeouts
    request.open_timeout = 300
    request.read_timeout = 300

    # Return the request object
    request
  end
  # :nocov:
end
