# frozen_string_literal: true

require "rails_helper"

describe VaDotGovAddressValidator::ClosestRegionalOfficeFinder do
  include HearingHelpers

  let(:closest_facility_id) { "vba_346" } # Seattle RO
  let(:possible_ro) { "vba_348" } # Portland RO that's has Seattle as an AHL
  let!(:facilities) do
    RegionalOffice.facility_ids.map do |id|
      (id == possible_ro) ? mock_facility_data(id: id, distance: 0) : mock_facility_data(id: id, distance: 200)
    end
  end

  subject do
    VaDotGovAddressValidator::ClosestRegionalOfficeFinder.new(
      closest_facility_id: closest_facility_id,
      facilities: facilities
    )
  end

  it "finds the closest RO based on facility id" do
    expect(subject.call).to eq "RO48" # Portland RO
  end

  context "when a distance is missing" do
    let!(:facilities) do
      RegionalOffice.facility_ids.map do |id|
        (id == possible_ro) ? mock_facility_data(id: id, distance: nil) : mock_facility_data(id: id, distance: 200)
      end
    end

    it "raises an error" do
      error_message = "Distances are missing from possible regional office."
      expect { subject.call }.to raise_error(Caseflow::Error::SerializableError).with_message(error_message)
    end
  end
end

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
