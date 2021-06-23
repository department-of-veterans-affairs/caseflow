# frozen_string_literal: true

module AppealConcern
  extend ActiveSupport::Concern

  delegate :station_key, to: :regional_office

  def regional_office
    return nil if regional_office_key.nil?

    @regional_office ||= begin
                            RegionalOffice.find!(regional_office_key)
                         rescue RegionalOffice::NotFoundError
                           nil
                          end
  end

  def regional_office_name
    return if regional_office.nil?

    "#{regional_office.city}, #{regional_office.state}"
  end

  def closest_regional_office_label
    return if closest_regional_office.nil?

    return "Central Office" if closest_regional_office == "C"

    RegionalOffice.find!(closest_regional_office).name
  end

  def veteran_name
    veteran_name_object.formatted(:form)
  end

  def veteran_full_name
    veteran_name_object.formatted(:readable_full)
  end

  def veteran_fi_last_formatted
    veteran_name_object.formatted(:readable_fi_last_formatted)
  end

  def appellant_name
    if appellant_first_name
      [appellant_first_name, appellant_middle_initial, appellant_last_name].select(&:present?).join(" ")
    end
  end

  # JOHN S SMITH => John S Smith
  def appellant_fullname_readable
    appellant_name&.titleize
  end

  def appellant_last_first_mi
    # returns appellant name in format <last>, <first> <middle_initial>.
    if appellant_first_name
      name = "#{appellant_last_name}, #{appellant_first_name}"
      "#{name} #{appellant_middle_initial}." if appellant_middle_initial
    end
  end

  def appellant_tz
    timezone_identifier_for_address(appellant_address)
  end

  def representative_tz
    timezone_identifier_for_address(representative_address)
  end

  #
  # This section was added to deal with displaying FNOD information in various places.
  # Currently, the FNOD information is used by both queue and hearings in:
  # - FnodBanner.jsx
  # - FnodBadge.jsx
  #
  # veteran_is_not_claimant is implemented differently in Appeal and LegacyAppeal
  # - Appeal: The result depends on 'veteran_is_not_claimant' field in the caseflow DB
  # - LegacyAppeal: The result depends on if 'appellant_first_name' exists in VACOLS

  def appellant_is_veteran
    !veteran_is_not_claimant
  end

  def veteran_is_deceased
    veteran_death_date.present?
  end

  def veteran_appellant_deceased?
    veteran_is_deceased && appellant_is_veteran
  end

  def veteran_death_date
    veteran&.date_of_death
  end

  def veteran_death_date_reported_at
    veteran&.date_of_death_reported_at
  end

  # End FNOD section

  private

  # TODO: this is named "veteran_name_object" to avoid name collision, refactor
  # the naming of the helper methods.
  def veteran_name_object
    FullName.new(veteran_first_name, veteran_middle_initial, veteran_last_name)
  end

  def timezone_identifier_for_address(addr)
    return if addr.blank?

    # Use an address object if this is a hash
    address_obj = addr.is_a?(Hash) ? Address.new(addr) : addr

    # APO/FPO/DPO addresses do not have time zones so we don't attempt to fetch them.
    return if address_obj.military_or_diplomatic_address?

    begin
      TimezoneService.address_to_timezone(address_obj).identifier
    rescue StandardError => error
      Raven.capture_exception(error)
      nil
    end
  end
end
