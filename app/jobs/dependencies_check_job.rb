# frozen_string_literal: true

class DependenciesCheckJob < ApplicationJob
  queue_with_priority :low_priority

  def perform(_http_library = HTTPI)
    return log_missing_env_var if monitor_url.blank?

    Rails.cache.write(:dependencies_report, monitor_response.raw_body)
  rescue StandardError => error
    log_message = "There was a problem with HTTP request to #{monitor_url}: #{error}"
    Rails.logger.error(log_message)
  end

  private

  def log_missing_env_var
    Rails.logger.error "ENV[\"MONITOR_URL\"] not set"
  end

  def monitor_response
    http_library.get(monitor_url, :httpclient)
  end

  def monitor_url
    ENV["MONITOR_URL"]
  end

  def http_library
    arguments.first || HTTPI
  end
end
