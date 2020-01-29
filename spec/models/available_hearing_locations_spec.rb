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

  describe("#formatted_facility_type") do
    it ("correctly formats facility type") do
      expect(location1.formatted_facility_type).to eq("(BVA) ")
      expect(location2.formatted_facility_type).to eq("(RO) ")
    end
  end

  describe("#formatted_location") do
    it ("correctly formats location") do
      expect(location1.formatted_location).to eq("#{location1.city}, #{location1.state} #{location1.formatted_facility_type}")
      expect(location2.formatted_location).to eq("#{location2.city}, #{location2.state} #{location2.formatted_facility_type}")
    end
  end
end
