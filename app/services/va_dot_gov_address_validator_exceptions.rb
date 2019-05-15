# frozen_string_literal: true

# class to handle exceptions in AHL logic made due to policy decisions

class VaDotGovAddressValidatorExceptions
  class << self
    def map_country_code_to_state(va_dot_gov_address)
      case va_dot_gov_address[:country_code]
      # Guam, American Samoa, Marshall Islands, Micronesia, Northern Mariana Islands, Palau
      when "GQ", "AQ", "RM", "FM", "CQ", "PS"
        "HI"
      # Philippine Islands
      when "PH", "RP", "PI"
        "PI"
      # Puerto Rico, Vieques, U.S. Virgin Islands
      when "VI", "VQ", "PR"
        "PR"
      when "US", "USA"
        va_dot_gov_address[:state_code]
      end
    end

    def veteran_requested_central_office?(appeal)
      appeal.is_a?(LegacyAppeal) && appeal.hearing_request_type == :central_office
    end

    def except_delaware(closest_regional_office)
      # Delaware's RO is not actually an RO
      # So we assign all appeals with appellants that live in Delaware to Philadelphia
      (closest_regional_office == "RO60") ? "RO10" : closest_regional_office
    end

    def include_san_antonio_satellite_office(facility_ids)
      # veterans whose closest AHL is San Antonio should have Houston as the RO
      # even though Waco may be closer. This is a RO/AHL policy quirk.
      # see https://github.com/department-of-veterans-affairs/caseflow/issues/9858
      facility_ids << "vha_671BY"
    end

    def facility_is_san_antonio_satellite_office?(facility_id)
      facility_id == "vha_671BY"
    end
  end
end
