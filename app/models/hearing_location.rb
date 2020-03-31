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
    return Constants::REGIONAL_OFFICE_FACILITY_ADDRESS["VACO"]["zip"] if vba_372?

    super
  end

  def street_address
    key = vba_372? ? "VACO" : facility_id
    addr = Constants::REGIONAL_OFFICE_FACILITY_ADDRESS[key]

    return unless addr

    addr["address_1"]
  end

  def timezone
    key = vba_372? ? "VACO" : facility_id
    tz = Constants::REGIONAL_OFFICE_FACILITY_ADDRESS[key]

    return unless tz

    tz["timezone"]
  end

  private

  def vba_372?
    facility_id == "vba_372"
  end
end
