class DependenciesReportService
  class << self
    # this method is in case we need list of dependencies/services that are degraded
    def find_degraded_dependencies
      str_report = Rails.cache.read(:dependencies_report)
      return [] if !str_report
      report = JSON.parse str_report
      report.values.each_with_object([]) do |element, result|
        result << element["name"] if element["up_rate_5"].to_i < 50
      end
    end

    def outage_present?
      case Rails.cache.read(:degraded_service_banner)
      when :always_show
        return true
      when :never_show
        return false
      end
      find_degraded_dependencies.present?
    rescue => error
      Rails.logger.warn "Exception thrown while checking dependency "\
        "status: #{error}"
      false
    end
  end
end
