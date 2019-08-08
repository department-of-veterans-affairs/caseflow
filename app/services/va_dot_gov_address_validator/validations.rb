# frozen_string_literal: true

module VaDotGovAddressValidator::Validations
  private

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
      valid_address[:state_code]
    end
  end

  def valid_states
    @valid_states ||= RegionalOffice::CITIES.values.reject { |ro| ro[:facility_locator_id].nil? }.pluck(:state)
  end

  def error_handler
    @error_handler ||= VaDotGovAddressValidator::ErrorHandler.new(appeal: appeal, appellant_address: address)
  end

  def fail_if_unable_to_validate_address
    raise valid_address_response.error if valid_address.nil? # rubocop:disable Style/SignalException
  end

  def state_code_error
    if state_code_for_regional_office.nil? || !valid_states.include?(state_code_for_regional_office)
      Caseflow::Error::VaDotGovForeignVeteranError.new(
        code: 500,
        message: "Appellant address is not in US territories."
      )
    end
  end

  def error_status
    @error_status ||= if valid_address.blank?
                        error_handler.handle(valid_address_response.error)
                      elsif state_code_error.present?
                        error_handler.handle(state_code_error)
                      elsif !closest_regional_office_response.success?
                        error_handler.handle(closest_regional_office_response.error)
                      elsif !available_hearing_locations_response.success?
                        error_handler.handle(available_hearing_locations_response.error)
                      end
  end

  def closest_regional_office_with_exceptions
    # Delaware's RO is not actually an RO
    # So we assign all appeals with appellants that live in Delaware to Philadelphia
    (closest_regional_office == "RO60") ? "RO10" : closest_regional_office
  end

  def appeal_is_legacy_and_veteran_requested_central_office?
    appeal.is_a?(LegacyAppeal) && appeal.hearing_request_type == :central_office
  end

  def appeal_is_legacy_and_veteran_lives_in_va_or_md?
    appeal.is_a?(LegacyAppeal) && %w[VA MD].include?(state_code_for_regional_office)
  end

  def closest_regional_office_facility_id_is_san_antonio?
    closest_regional_office_facility_id == "vha_671BY"
  end

  def veteran_lives_in_texas?
    state_code_for_regional_office == "TX"
  end
end
