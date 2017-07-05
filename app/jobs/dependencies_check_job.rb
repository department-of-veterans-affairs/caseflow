class DependenciesCheckJob < ActiveJob::Base
  queue_as :default

  def perform
    request = HTTPI::Request.new
    request.url = ENV["MONITOR_SERVICES_URL"]
    http = HTTPI.get(request, :curb)
    response = JSON.parse http.raw_body
    Rails.cache.write("dependencies_outage", false)
    begin
      response.values.each do |hash|
        if hash["up_rate_5"].to_i < 51
          Rails.cache.write("dependencies_outage", true)
          Rails.logger.error "Dependencies outage: #{hash["name"]}"
        end
      end
    rescue
       Rails.logger.info "Invalid response from #{request.url}"
    end
  end
end

