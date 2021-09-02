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

    def get_message_subject_and_body_from_event(email_event:)
      get_message_subject_and_body(external_message_id: email_event.external_message_id)
    end

    def get_message_from_event(email_event:)
      get_message(external_message_id: email_event.external_message_id)
    end

    def get_sent_status(external_message_id:)
      # assumes the email has only one recipient
      get_recipients(external_message_id: external_message_id).first&.dig(STATUS_FIELD_NAME)
    end

    def get_recipients(external_message_id:)
      # Construct the endpoint from the email event
      path = "#{external_message_id}/recipients"

      response = send_request_and_wrap_response(path)

      response.body
    end

    def get_message_subject_and_body(external_message_id:)
      message_details = get_message(external_message_id: external_message_id)

      {
        subject: message_details["subject"],
        body: strip_html_and_format(message_details["body"])
      }
    end

    def get_message(external_message_id:)
      # Construct the endpoint from the email event
      path = external_message_id

      response = send_request_and_wrap_response(path)

      response.body
    end

    private

    def send_request_and_wrap_response(path)
      # Send the request to the gov delivery API
      response = send_gov_delivery_request(path, :get)
      return if response.nil?

      gd_response = ExternalApi::GovDeliveryService::Response.new(response)

      fail gd_response.error if gd_response.error.present?

      gd_response
    end

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

    def strip_html_and_format(text)
      # remove all HTML tags and newline characters, then replace any
      # group of more than one space with a newline character
      Rails::Html::FullSanitizer.new.sanitize(text).gsub(/(\n|\r)/, "").gsub(/[ ]{2,}/, "\n")
    end
  end
end
