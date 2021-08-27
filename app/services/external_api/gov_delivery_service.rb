# frozen_string_literal: true

require "json"

class ExternalApi::GovDeliveryService
  BASE_URL = ENV["GOVDELIVERY_SERVER"]
  AUTH_TOKEN = ENV["GOVDELIVERY_TOKEN"]
  CERT_FILE_LOCATION = ENV["SSL_CERT_FILE"]
  STATUS_FIELD_NAME = "status"

  class << self
    def get_sent_status_from_event(email_event:)
      get_sent_status(external_message_id: email_event.external_message_id)
    end

    def get_recipients_from_event(email_event:)
      get_recipients(external_message_id: email_event.external_message_id)
    end

    def get_sent_status(external_message_id:)
      # assumes the email has only one recipient
      get_recipients(external_message_id: external_message_id).first[STATUS_FIELD_NAME]
    end

    def get_recipients(external_message_id:)
      # Construct the endpoint from the email event
      path = "#{external_message_id}/recipients"

      # Send the request to the gov delivery API
      response = send_gov_delivery_request(path, :get)
      return if response.nil?

      gd_response = ExternalApi::GovDeliveryService::Response.new(response)

      fail gd_response.error if gd_response.error.present?

      # Return the body of the GovDelivery Response
      gd_response.body
    end

    private

    def send_gov_delivery_request(endpoint, method, body: nil)
      url = URI::DEFAULT_PARSER.escape("https://#{BASE_URL}#{endpoint}")

      # Create the API request
      request = create_gov_delivery_request(url)

      # Attach the body and optional headers if present
      request.body = body.to_json unless body.nil?
      request.headers["Content-Type"] = "application/json" if method == :post

      MetricsService.record(
        "#{BASE_URL} #{method.to_s.upcase} request to #{url}",
        service: :gov_delivery,
        name: endpoint
      ) do
        case method
        when :get
          HTTPI.get(request)
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
  end
end
