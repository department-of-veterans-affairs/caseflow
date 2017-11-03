class DependenciesCheckJob < ActiveJob::Base
  queue_as :low_priority

  def perform
    if ENV["MONITOR_URL"].present?
      begin
        request = HTTPI::Request.new
        request.url = ENV["MONITOR_URL"]
        http = HTTPI.get(request, :httpclient)
        Rails.cache.write(:dependencies_report, http.raw_body)
      rescue
        Rails.logger.error "There was a problem with HTTP request to #{ENV['MONITOR_URL']}"
      end
    else
      Rails.logger.error "ENV[\"MONITOR_URL\"] not set"
    end
  end
end
