# frozen_string_literal: true

require "json"
require "base64"
require "digest"


class ExternalApi::VANotifyService
  BASE_URL = ENV["notification-api-url"] || ""
  CLIENT_SECRET = ENV["service-api-key"] || ""
  SERVICE_ID = ""
  SEND_EMAIL_NOTIFICATION_ENDPOINT = "/v2/notifications/email"
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
      request.headers = headers.merge(Authorization: "Bearer " + CLIENT_SECRET)
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

    def send_notifications 
        
    end

    def get_status

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
  
    end

    def get_callback
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
  end
  
end
