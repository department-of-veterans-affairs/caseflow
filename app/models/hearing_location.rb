# frozen_string_literal: true

class HearingLocation < CaseflowRecord
  belongs_to :hearing, polymorphic: true

  # backwards compat data fix for "central" office.
  # we have mistakenly been using facility_id "vba_372"
  # and should have been using the VACO RO (101) which does not have a facility_id
  # For the purposes of the Hearings API, override name and address
  # where appropriate till we can remove vba_372 from the list of eligible locations.
  def name
    return Constants::REGIONAL_OFFICE_INFORMATION["VACO"]["label"] if vba_372?

    super
  end

  def zip_code
    return facility_address("VACO")["zip"] if vba_372?

    super
  end

  def street_address
    addr = facility_address(key)

    return unless addr

    addr["address_1"]
  end

  def timezone
    tz = facility_address(key)

    return unless tz

    tz["timezone"]
  end

  def full_address
    full_addr = [street_address, facility_address(key)["address_2"], facility_address(key)["address_3"]]
      .reject(&:blank?).join(" ")

    return if full_addr.blank?

    "#{full_addr}, #{[city, state, zip_code].reject(&:blank?).join(' ')}"
  end

  private

  def key
    vba_372? ? "VACO" : facility_id
  end

  def vba_372?
    facility_id == "vba_372"
  end

  def facility_address(location_key)
    Constants::REGIONAL_OFFICE_FACILITY_ADDRESS[location_key]
  end
end
