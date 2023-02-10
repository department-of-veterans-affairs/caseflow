# frozen_string_literal: true

class DependenciesReportService
  class << self
    ALL_DEPENDENCIES_MAP = {
      degraded_service_banner_bgs: "BGS",
      degraded_service_banner_vbms: "VBMS",
      degraded_service_banner_vva: "VVA",
      degraded_service_banner_vacols: "VACOLS",
      degraded_service_banner_gov_delivery: "GOV DELIVERY",
      degraded_service_banner_va_dot_gov: "VA.GOV"
    }.freeze

    def dependencies_report
      # Read All Dependencies written to the cache
      cache_degraded_services = Rails.cache.read_multi(*ALL_DEPENDENCIES_MAP.keys)
      # Create New Array, with key and value
      cache_degraded_services.reduce([]) do |array, (key, value)|
        # Return Array with only the value :display
        array.push(ALL_DEPENDENCIES_MAP[key]) if value == :display
        array
      end
    rescue StandardError => error
      Rails.logger.warn "Exception thrown while checking dependency "\
        "status: #{error}"
      false
    end
  end
end
