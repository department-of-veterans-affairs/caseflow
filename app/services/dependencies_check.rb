class DependenciesCheck

  class << self
    # this method is in case we need list of dependencies/services that are degraded
    def find_degraded_dependencies
      begin
        report = JSON.parse Rails.cache.read(:dependencies_report)
        dependencies_outage = []
        report.values.each do |hash|
          if hash["up_rate_5"].to_i < 51
            dependencies_outage << hash["name"]
            Rails.logger.error "Dependencies outage: #{hash["name"]}"
          end
        end
      rescue
         Rails.logger.info "Invalid response from #{ENV["MONITOR_URL"]}"
      end
      dependencies_outage
    end

    def outage_present?
      find_degraded_dependencies.present?
    end
  end
end
