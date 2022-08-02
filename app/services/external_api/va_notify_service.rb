# frozen_string_literal: true

require "json"

class ExternalApi::VANotifyService
  BASE_URL = ENV["notification-api-url"] || "https://dev-api.va.gov/vanotify"
  CLIENT_SECRET = ENV["notification-client-secret"] || ""

  SEND_EMAIL_NOTIFICATION_ENDPOINT = "/v2/notifications/email"
  GET_STATUS_ENDPOINT = "/v2/notifications/"
  

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

    def create_callback

    end

    def get_callback
        
    end

    def create_template

    end

    def get_template

    end
  end
end
