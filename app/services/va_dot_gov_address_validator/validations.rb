# frozen_string_literal: true

module VaDotGovAddressValidator::Validations
  private

  # :nocov:
  def map_country_code_to_state
    case valid_address[:country_code]
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
      valid_address.dig(:state_code)
    end
  end
  # :nocov:

  def valid_states
    @valid_states ||= RegionalOffice.cities.select(&:facility_id?).map(&:state)
  end

  def error_handler
    @error_handler ||= VaDotGovAddressValidator::ErrorHandler.new(appeal: appeal, appellant_address: address)
  end

  def state_code_error
    if !valid_states.include?(state_code)
      Caseflow::Error::VaDotGovForeignVeteranError.new(
        code: 500,
        message: "Appellant address is not in US territories."
      )
    end
  end

  def valid_address_error
    if address.nil?
      return Caseflow::Error::VaDotGovNullAddressError.new(
        code: 500,
        message: "Appellant address is missing in VBMS."
      )
    end

    valid_address_response.error
  end

  def error_status
    @error_status ||= if valid_address_error.present?
                        error_handler.handle(valid_address_error)
                      elsif state_code_error.present?
                        error_handler.handle(state_code_error)
                      elsif !closest_ro_response.success?
                        error_handler.handle(closest_ro_response.error)
                      elsif !available_hearing_locations_response.success?
                        error_handler.handle(available_hearing_locations_response.error)
                      end
  end

  def closest_regional_office_with_exceptions
    # Delaware's RO is not actually an RO
    # So we assign all appeals with appellants that live in Delaware to Philadelphia
    (closest_regional_office == "RO60") ? "RO10" : closest_regional_office
  end

  def closest_regional_office_facility_id_is_san_antonio?
    closest_ro_facility_id == "vha_671GS"
  end

  def closest_regional_office_facility_id_is_el_paso?
    closest_ro_facility_id == "vba_349i"
  end

  def appeal_is_legacy_and_veteran_requested_central_office?
    appeal.is_a?(LegacyAppeal) && appeal.current_hearing_request_type == :central_office
  end

  def veteran_lives_in_texas?
    state_code == "TX"
  end
end
