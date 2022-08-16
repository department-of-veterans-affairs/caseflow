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

       DEGRADED_DEPENDENCIES = []

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

      #BGS
      when :display_bgs
        return DEGRADED_DEPENDENCIES.push("BGS").uniq
      when :hide_bgs
        DEGRADED_DEPENDENCIES.delete("BGS")
        return DEGRADED_DEPENDENCIES.uniq

      #VBMS
      when :display_vbms
          return DEGRADED_DEPENDENCIES.push("VBMS").uniq
      when :hide_vbms
        DEGRADED_DEPENDENCIES.delete("VBMS")
        return DEGRADED_DEPENDENCIES.uniq

      #VVA
      when :display_vva
        return DEGRADED_DEPENDENCIES.push("VVA").uniq
      when :hide_vva
      DEGRADED_DEPENDENCIES.delete("VVA")
      return DEGRADED_DEPENDENCIES.uniq

      #VACOLS
      when :display_vacols
        return DEGRADED_DEPENDENCIES.push("VACOLS").uniq
      when :hide_vacols
        DEGRADED_DEPENDENCIES.delete("VACOLS")
        return DEGRADED_DEPENDENCIES.uniq

      #GOV_DELIVERY
      when :display_gov_delivery
        return DEGRADED_DEPENDENCIES.push("GOV_DELIVERY").uniq
      when :hide_gov_delivery
        DEGRADED_DEPENDENCIES.delete("GOV_DELIVERY")
        return DEGRADED_DEPENDENCIES.uniq

      #VA_DOT_GOV
      when :display_va_dot_gov
        return DEGRADED_DEPENDENCIES.push("VA_DOT_GOV").uniq
      when :hide_va_dot_gov
        DEGRADED_DEPENDENCIES.delete("VA_DOT_GOV")
        return DEGRADED_DEPENDENCIES.uniq

      #ALL DEPENDENCIES
      when :always_show
        return DEGRADED_DEPENDENCIES.push(ALL_DEPENDENCIES)

      #CLEAR ALL DEGRADED DEPENDENCIES
      when :clear_all
        return DEGRADED_DEPENDENCIES.clear()
      end
      degraded_dependencies
    rescue StandardError => error
      Rails.logger.warn "Exception thrown while checking dependency "\
        "status: #{error}"
      false
    end
  end
end
