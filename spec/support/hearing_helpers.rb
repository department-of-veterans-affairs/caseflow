# frozen_string_literal: true

module HearingHelpers
  def mock_facility_data(id:, distance: 10)
    {
      facility_id: id,
      type: "",
      distance: distance,
      facility_type: "",
      name: "Fake Name",
      classification: "",
      lat: 0.0,
      long: 0.0,
      address: "Fake Address",
      city: "Fake City",
      state: "PA",
      zip_code: "00000"
    }
  end
end
