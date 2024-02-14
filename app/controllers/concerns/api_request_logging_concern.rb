# frozen_string_literal: true

module ApiRequestLoggingConcern
  extend ActiveSupport::Concern

  included do
    before_action :log_api_request
  end

  def log_api_request
    log = "request_id: " + request.uuid.to_s + "\n" \
          "endpoint: " + request.fullpath.to_s + "\n" \
          "payload: " + params.to_s + "\n" \
          "method: " + request.method.to_s + "\n" \
          "request_time: " + Time.now.to_s

    Rails.logger.info(log)
  end
end
