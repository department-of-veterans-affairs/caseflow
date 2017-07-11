class DependenciesCheck

  class << self
    # this method is in case we need list of dependencies/services that are degraded
    def find_degraded_dependencies
      begin
        report = JSON.parse Rails.cache.read(:dependencies_report)
        report.values.reduce([]) do |result, element|
          Rails.logger.error "Dependencies outage: #{element["name"]}"
          result << element["name"] if element["up_rate_5"].to_i < 50
          result
        end
      rescue
         Rails.logger.info "Invalid response from #{ENV["MONITOR_URL"]}"
      end
    end

    def outage_present?
      find_degraded_dependencies.present?
    end
  end
end
