# frozen_string_literal: true

describe AvailableHearingLocations, :all_dbs do
  let!(:appeal) { create(:appeal) }

  let!(:location1) do
    AvailableHearingLocations.create(
      appeal: appeal,
      city: "New York",
      state: "NY",
      distance: 20,
      facility_type: "va_benefits_facility",
      facility_id: "vba_372"
    )
  end

  let!(:location2) do
    AvailableHearingLocations.create(
      appeal: appeal,
      city: "Los Angeles",
      state: "CA",
      distance: 1000,
      facility_type: "va_benefits_facility",
      classification: "Regional Office"
    )
  end

  let!(:location3) do
    AvailableHearingLocations.create(
      appeal: appeal,
      city: "Chicago",
      state: "IL",
      distance: 1000,
      facility_type: "vet_center"
    )
  end

  let!(:location4) do
    AvailableHearingLocations.create(
      appeal: appeal
    )
  end

  describe "#to_hash" do
    it "it serializes location correctly" do
      expect(location1.to_hash).to eq(
        name: nil,
        address: nil,
        city: location1.city,
        state: location1.state,
        distance: location1.distance,
        facility_id: location1.facility_id,
        facility_type: location1.facility_type,
        classification: nil,
        zip_code: nil,
        formatted_facility_type: location1.formatted_facility_type
      )
    end
  end

  describe "#formatted_facility_type" do
    it "correctly formats facility type" do
      expect(location1.formatted_facility_type).to eq("(BVA)")
      expect(location2.formatted_facility_type).to eq("(RO)")
      expect(location3.formatted_facility_type).to eq("(Vet Center)")
      expect(location4.formatted_facility_type).to eq("")
    end
  end

  describe "#determine_vba_facility_type" do
    it "determines correct vba facility" do
      expect(location2.determine_vba_facility_type).to eq("(RO)")
    end
  end

  describe "#formatted_location" do
    it "correctly formats location" do
      expect(location1.formatted_location).to eq(
        "#{location1.city}, #{location1.state} #{location1.formatted_facility_type}"
      )
    end
  end
end
