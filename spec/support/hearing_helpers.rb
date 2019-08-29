# frozen_string_literal: true

module HearingHelpers
  def mock_facility_data(id:, distance: 10, city: "Fake City", state: "PA")
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
      city: city,
      state: state,
      zip_code: "00000"
    }
  end
end
