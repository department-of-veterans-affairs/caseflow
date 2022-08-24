# frozen_string_literal: true

require "json"
require "base64"
require "digest"
class ExternalApi::VANotifyService
  BASE_URL = ENV["VA_NOTIFY_API_URL"]
  CLIENT_SECRET = ENV["VA_NOTIFY_API_KEY"]
  SERVICE_ID = ENV["VA_NOTIFY_SERVICE_ID"]
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
    # Send the email and sms notifications
    # @param {status} The appeal status for a template that requires it
    def send_notifications(participant_id, appeal_id, email_template_id, status = "")
      email_response = send_va_notify_request(email_request(participant_id, appeal_id, email_template_id, status))
      Rails.logger.info(email_response)
      email_response
    end

    # Get the status of a notification
    def get_status(notification_id)
      request = {
        headers: HEADERS,
        endpoint: GET_STATUS_ENDPOINT + notification_id, method: :get
      }
      send_va_notify_request(request)
    end

    private

    # Generate the JWT token
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

    # Remove any illegal characters and keeps source at proper format
    def base64url(source)
      encoded_source = Base64.encode64(source)
      encoded_source = encoded_source.sub(/=+$/, "")
      encoded_source = encoded_source.tr("+", "-")
      encoded_source = encoded_source.tr("/", "_")
      encoded_source
    end

    # Build an email request object
    def email_request(participant_id, appeal_id, email_template_id, status)
      request = {
        body: {
          template_id: email_template_id,
          reference: appeal_id,
          recipient_identifier: {
            id_type: "PID",
            id_value: participant_id
          },
          personalisation: nil
        },
        headers: HEADERS,
        endpoint: SEND_EMAIL_NOTIFICATION_ENDPOINT, method: :post
      }
      if status
        # If a status is given then it will be added to the request object
        request[:body][:personalisation] = { appeal_status: status }
      end
      request
    end

    # Build a sms request object
    def sms_request(participant_id, appeal_id, sms_template_id, status)
      request = {
        body: {
          reference: appeal_id,
          template_id: sms_template_id,
          recipient_identifier: {
            id_type: "PID",
            id_value: participant_id
          },
          personalisation: nil
        },
        headers: HEADERS,
        endpoint: SEND_SMS_NOTIFICATION_ENDPOINT, method: :post
      }
      if status
        # If a status is given then it will be added to the request object
        request[:body][:personalisation] = { appeal_status: status }
      end
      request
    end

    # rubocop:disable Metrics/MethodLength
    # Build and send the request to the server
    def send_va_notify_request(query: {}, headers: {}, endpoint:, method: :get, body: nil)
      url = URI.escape(BASE_URL + endpoint)
      request = HTTPI::Request.new(url)
      request.query = query
      request.open_timeout = 30
      request.read_timeout = 30
      request.body = body.to_json unless body.nil?
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
  end
end
