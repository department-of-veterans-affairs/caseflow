# frozen_string_literal: true

require "json"
require "base64"
require "digest"
class ExternalApi::VANotifyService
  BASE_URL = ENV["VA_NOTIFY_API_URL"]
  CLIENT_SECRET = ENV["VA_NOTIFY_API_KEY"]
  SERVICE_ID = ENV["VA_NOTIFY_SERVICE_ID"]
  SENDER_ID = ENV["VA_NOTIFY_SMS_SENDER_ID"]
  TOKEN_ALG = ENV["VA_NOTIFY_TOKEN_ALG"]
  SEND_EMAIL_NOTIFICATION_ENDPOINT = "/v2/notifications/email"
  SEND_SMS_NOTIFICATION_ENDPOINT = "/v2/notifications/sms"
  GET_STATUS_ENDPOINT = "/v2/notifications/"
  TEMPLATE_ENDPOINT = "/service/#{SERVICE_ID}/template"
  CALLBACK_ENDPOINT = "/service/#{SERVICE_ID}/callback"
  HEADERS = {
    "Content-Type": "application/json", Accept: "application/json"
  }.freeze

  class << self
    # Purpose: Send the email notifications
    #
    # Params: Details from appeal for notification
    #         participant_id (from appeal for which notification is being generated)
    #         notification_id: id of the associated Notification in the db
    #         email_template_id: taken from notification_event table corresponding to correct notification template
    #         first_name: appellant's first name
    #         docket_number: appeals docket number
    #         status: appeal status for quarterly notification (not necessary for other notifications)
    # Return: email_response: JSON response from VA Notify API
    def send_email_notifications(
      participant_id,
      notification_id,
      email_template_id,
      first_name,
      docket_number,
      status = ""
    )
      email_response = send_va_notify_request(
        email_request(participant_id, notification_id, email_template_id, first_name, docket_number, status)
      )
      log_info(email_response)
      email_response
    end

    # Purpose: Send the sms notifications
    #
    # Params: Details from appeal for notification
    #         participant_id (from appeal for which notification is being generated)
    #         notification_id: id of the associated Notification in the db
    #         sms_template_id: taken from notification_event table corresponding to correct notification template
    #         first_name: appellant's first name
    #         docket_number: appeals docket number
    #         status: appeal status for quarterly notification (not necessary for other notifications)
    # Return: sms_response: JSON response from VA Notify API
    def send_sms_notifications(participant_id, notification_id, sms_template_id, first_name, docket_number, status = "")
      sms_response = send_va_notify_request(
        sms_request(participant_id, notification_id, sms_template_id, first_name, docket_number, status)
      )
      log_info(sms_response)
      sms_response
    end

    # Purpose: Get the status of a notification
    def get_status(notification_id)
      request = {
        headers: HEADERS,
        endpoint: GET_STATUS_ENDPOINT + notification_id, method: :get
      }
      send_va_notify_request(request)
    end

    private

    # Purpose: Generate the JWT token
    #
    # Params: none
    #
    # Return: token needed for authentication
    def generate_token
      jwt_secret = CLIENT_SECRET
      header = {
        typ: "JWT",
        alg: TOKEN_ALG
      }
      current_timestamp = DateTime.now.strftime("%Q").to_i / 1000.floor
      data = {
        iss: SERVICE_ID,
        iat: current_timestamp
      }
      stringified_header = header.to_json.encode("UTF-8")
      encoded_header = base64url(stringified_header)
      stringified_data = data.to_json.encode("UTF-8")
      encoded_data = base64url(stringified_data)
      token = "#{encoded_header}.#{encoded_data}"
      signature = OpenSSL::HMAC.digest("SHA256", jwt_secret, token)
      signature = base64url(signature)
      signed_token = "#{token}.#{signature}"
      signed_token
    end

    # Purpose: Remove any illegal characters and keeps source at proper format
    #
    # Params: string
    #
    # Return: sanitized string
    def base64url(source)
      encoded_source = Base64.encode64(source)
      encoded_source = encoded_source.sub(/=+$/, "")
      encoded_source = encoded_source.tr("+", "-")
      encoded_source = encoded_source.tr("/", "_")
      encoded_source
    end

    # Purpose: Build an email request object
    #
    # Params: Details from appeal for notification
    #         participant_id (from appeal for which notification is being generated)
    #         notification_id: id of the associated Notification in the db
    #         email_template_id: taken from notification_event table corresponding to correct notification template
    #         first_name: appellant's first name (this will default to 'Appellant' if there is no first name)
    #         docket_number: appeals docket number
    #         status: appeal status for quarterly notification (not necessary for other notifications)
    #
    # Return: Request hash
    def email_request(participant_id, notification_id, email_template_id, first_name, docket_number, status)
      request = {
        body: {
          template_id: email_template_id,
          reference: notification_id,
          recipient_identifier: {
            id_type: "PID",
            id_value: participant_id
          },
          personalisation: {
            first_name: first_name, docket_number: docket_number, status: status
          }
        },
        headers: HEADERS,
        endpoint: SEND_EMAIL_NOTIFICATION_ENDPOINT, method: :post
      }
      if !status.empty?
        # If a status is given then it will be added to the request object
        request[:body][:personalisation][:appeal_status] = status
      end
      request
    end

    # Purpose: Build an sms request object
    #
    # Params: Details from appeal for notification
    #         participant_id (from appeal for which notification is being generated)
    #         notification_id: id of the associated Notification in the db
    #         sms_template_id: taken from notification_event table corresponding to correct notification template
    #         first_name: appellant's first name (this will default to 'Appellant' if there is no first name)
    #         docket_number: appeals docket number
    #         status: appeal status for quarterly notification (not necessary for other notifications)
    #
    # Return: Request hash
    def sms_request(participant_id, notification_id, sms_template_id, first_name, docket_number, status)
      request = {
        body: {
          reference: notification_id,
          template_id: sms_template_id,
          recipient_identifier: {
            id_type: "PID",
            id_value: participant_id
          },
          sms_sender_id: SENDER_ID || "",
          personalisation: {
            first_name: first_name, status: status, docket_number: docket_number
          }
        },
        headers: HEADERS,
        endpoint: SEND_SMS_NOTIFICATION_ENDPOINT, method: :post
      }
      if !status.empty?
        # If a status is given then it will be added to the request object
        request[:body][:personalisation][:appeal_status] = status
      end
      request
    end

    # rubocop:disable Metrics/MethodLength
    # Purpose: Build and send the request to the server
    #
    # Params: general requirements for HTTP request
    #
    # Return: service_response: JSON from VA Notify or error
    def send_va_notify_request(query: {}, headers: {}, endpoint:, method: :get, body: nil)
      url = URI.escape(BASE_URL + endpoint)
      request = HTTPI::Request.new(url)
      request.query = query
      request.open_timeout = 30
      request.read_timeout = 30
      request.body = body.to_json unless body.nil?
      request.auth.ssl.ssl_version  = :TLSv1_2
      request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]
      request.headers = headers.merge(Authorization: "Bearer " + generate_token)
      sleep 1
      MetricsService.record("api.notifications.va.gov #{method.to_s.upcase} request to #{url}",
                            service: :va_notify,
                            name: endpoint) do
        case method
        when :get
          response = HTTPI.get(request)
          service_response = ExternalApi::VANotifyService::Response.new(response)
          fail service_response.error if service_response.error.present?

          service_response
        when :post
          response = HTTPI.post(request)
          service_response = ExternalApi::VANotifyService::Response.new(response)
          fail service_response.error if service_response.error.present?

          service_response
        else
          fail NotImplementedError
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    # Purpose: Method to be called with info need to be logged to the rails logger
    #
    # Params: info_message (Expecting a string) - Message to be logged to the logger
    #
    # Response: None
    def log_info(info_message)
      Rails.logger.info(info_message)
    end
  end
end
