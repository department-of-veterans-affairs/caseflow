# frozen_string_literal: true

class DependenciesReportService
  class << self
    ALL_DEPENDENCIES =
      ["BGS.FilenumberService",
       "BGS.PoaService",
       "BGS.AddressService",
       "BGS.OrganizationPoaService",
       "BGS.VeteranService",
       "BGS.AddressService",
       "BGS.BenefitsService",
       "BGS.ClaimantFlashesService",
       "BGS.PersonFilenumberService",
       "VACOLS",
       "VBMS",
       "VBMS.FindDocumentVersionReference",
       "VVA"].freeze

    # this method is in case we need list of dependencies/services that are degraded
    def degraded_dependencies
      str_report = Rails.cache.read(:dependencies_report)
      return [] if !str_report

      report = JSON.parse str_report
      report.values.each_with_object([]) do |element, result|
        result << element["name"] if element["up_rate_5"].to_i < 50
      end
    end

    def dependencies_report
      case Rails.cache.read(:degraded_service_banner)
      when :always_show
        return ALL_DEPENDENCIES
      when :never_show
        return []
      end
      degraded_dependencies
    rescue StandardError => error
      Rails.logger.warn "Exception thrown while checking dependency "\
        "status: #{error}"
      false
    end
  end
end
