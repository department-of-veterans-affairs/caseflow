# frozen_string_literal: true

class DependenciesReportService
  class << self

    ALL_DEPENDENCIES_KEYS =
      [:degraded_service_banner_bgs,
        :degraded_service_banner_vbms,
        :degraded_service_banner_vva,
        :degraded_service_banner_vacols,
        :degraded_service_banner_gov_delivery,
        :degraded_service_banner_va_dot_gov].freeze

    def dependencies_report

      keys = Rails.cache.read_multi(*ALL_DEPENDENCIES_KEYS)
          degraded_arr = keys.select { |k,v| v == :display }
          degraded_arr.keys()

    rescue StandardError => error
      Rails.logger.warn "Exception thrown while checking dependency "\
        "status: #{error}"
      false
    end
  end
end
