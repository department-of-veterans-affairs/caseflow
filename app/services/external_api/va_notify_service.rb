# frozen_string_literal: true

require "json"
require "base64"
require "digest"
class ExternalApi::VANotifyService
  BASE_URL = ENV["notification-api-url"] || ""
  CLIENT_SECRET = ENV["service-api-key"] || ""
  SERVICE_ID = ""
  SEND_EMAIL_NOTIFICATION_ENDPOINT = "/v2/notifications/email"
  SEND_SMS_NOTIFICATION_ENDPOINT = "/v2/notifications/sms"
  GET_STATUS_ENDPOINT = "/v2/notifications/"
  TEMPLATE_ENDPOINT = "/service/#{SERVICE_ID}/template"
  CALLBACK_ENDPOINT = "/service/#{SERVICE_ID}/callback"
  HEADERS = {
    "Content-Type": "application/json", Accept: "application/json"
  }.freeze

  class << self
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
          HTTPI.get(request)
        when :post
          HTTPI.post(request)
        end
      end
    end

    def send_notifications(email_address, email_template_id, sms_template_id = nil, phone_number = nil, status = "")
      email_response = send_va_notify_request(email_request(email_address, email_template_id, status))
      Rails.logger.info(email_response)
      if phone_number
        sms_response = send_va_notify_request(sms_request(phone_number, sms_template_id, status))
        Rails.logger.info(sms_response)
      end
    end

    def get_status(notification_id)
      request = {
        headers: HEADERS,
        endpoint: GET_STATUS_ENDPOINT + notification_id, method: :get
      }
      send_va_notify_request(request)
    end

    def create_callback(url, callback_type, bearer_token, callback_channel)
      request = {
        body: {
          url: url,
          callback_type: callback_type,
          bearer_token: bearer_token,
          callback_channel: callback_channel
        },
        headers: HEADERS,
        endpoint: CALLBACK_ENDPOINT, method: :post
      }
      send_va_notify_request(request)
    end

    def get_callbacks
      request = {
        headers: HEADERS,
        endpoint: CALLBACK_ENDPOINT, method: :get
      }
      send_va_notify_request(request)
    end

    private

    def generate_token
      jwt_secret = CLIENT_SECRET
      header = {
        typ: "JWT",
        alg: "HS256"
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
      signature = OpenSSL::HMAC.digest('SHA256', jwt_secret, token)
      signature = base64url(signature)
      signed_token = "#{token}.#{signature}"
      signed_token
    end

    def base64url(source)
      encoded_source = Base64.encode64(source)
      encoded_source = encoded_source.sub(/=+$/, '')
      encoded_source = encoded_source.gsub(/\+/, '-')
      encoded_source = encoded_source.gsub(/\//, '_')
      encoded_source
    end

    def email_request(email_address, email_template_id, status)
      request = {
        body: {
          template_id: email_template_id,
          email_address: email_address,
          personalisation: nil
        },
        headers: HEADERS,
        endpoint: SEND_EMAIL_NOTIFICATION_ENDPOINT, method: :post
      }
      if status
        request[:body][:personalisation] = { appeal_status: status }
      end
      request
    end

    def sms_request(phone_number, sms_template_id, status)
      request = {
        body: {
          template_id: sms_template_id,
          phone_number: phone_number,
          personalisation: nil
        },
        headers: HEADERS,
        endpoint: SEND_SMS_NOTIFICATION_ENDPOINT, method: :post
      }
      if status
        request[:body][:personalisation] = { appeal_status: status }
      end
      request
    end
  end
end
