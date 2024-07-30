# frozen_string_literal: true

module HearingLocationAndRegionalOfficeMixin
  # putpose: Provide a function that will return the 3 lines of the facility address
  # params: None
  # output: address line 1 through 3 of REGIONAL_OFFICE_FACILITY_ADDRESS that matched the facility id
  def full_street_address
    "#{street_address} #{facility_address(key)['address_2']}" \
    "#{facility_address(key)['address_3']}"
  end
end
