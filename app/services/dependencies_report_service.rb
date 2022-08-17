# frozen_string_literal: true

class DependenciesReportService
  class << self

    ALL_DEPENDENCIES_MAP = {
      degraded_service_banner_bgs: "BGS",
      degraded_service_banner_vbms: "VBMS",
      degraded_service_banner_vva: "VVA",
      degraded_service_banner_vacols: "VACOLS",
      degraded_service_banner_gov_delivery: "GOV DELIVERY",
      degraded_service_banner_va_dot_gov: "VA DOT GOV"
    }
      # [:degraded_service_banner_bgs,
      #   :degraded_service_banner_vbms,
      #   :degraded_service_banner_vva,
      #   :degraded_service_banner_vacols,
      #   :degraded_service_banner_gov_delivery,
      #   :degraded_service_banner_va_dot_gov].freeze

    def dependencies_report

      keys = Rails.cache.read_multi(*ALL_DEPENDENCIES_MAP.keys())
          degraded_arr = keys.select { |k,v| v == :display }
          # Display Systems = [:degraded_service_banner_bgs, :degraded_service_banner_vbms]
          displaySystems = degraded_arr.keys()
          # Loop through displaySystems with to create a new array with the NAME ["BGS", "VBMS"]
          displaySystems.map{|degradedServiceKey| ALL_DEPENDENCIES_MAP[degradedServiceKey] }

    rescue StandardError => error
      Rails.logger.warn "Exception thrown while checking dependency "\
        "status: #{error}"
      false
    end
  end
end
