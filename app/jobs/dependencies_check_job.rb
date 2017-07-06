class DependenciesCheckJob < ActiveJob::Base
  queue_as :default

  def perform
    report = poll_monitor
    Rails.cache.write(:dependencies_outage, nil)
    begin
      report.values.each do |hash|
        if hash["up_rate_5"].to_i < 51
          Rails.cache.write(:dependencies_outage, hash["name"])
          Rails.logger.error "Dependencies outage: #{hash["name"]}"
        end
      end
    rescue
       Rails.logger.info "Invalid response from #{ENV["MONITOR_URL"]}"
    end
  end

  def poll_monitor
    request = HTTPI::Request.new
    request.url = ENV["MONITOR_URL"]
    http = HTTPI.get(request, :curb)
    JSON.parse http.raw_body
  end
end

