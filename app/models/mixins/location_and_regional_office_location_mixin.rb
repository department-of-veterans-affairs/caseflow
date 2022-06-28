# frozen_string_literal: true

module LocationAndRegionalOfficeLocationMixin
  # putpose: Provide a function that will return the 3 lines of the facility address
  # params: None
  # output: address line 1 through 3 of REGIONAL_OFFICE_FACILITY_ADDRESS that matched the facility id
  def full_street_address
    address_line_1 = street_address
    address_line_2 = facility_address(key)["address_2"]
    address_line_3 = facility_address(key)["address_3"]
    "#{address_line_1} #{address_line_2}" \
    "#{address_line_3}"
  end
end
