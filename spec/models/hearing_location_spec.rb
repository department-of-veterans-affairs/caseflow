# frozen_string_literal: true

describe HearingLocation do
  describe "#street_address" do
    it "pulls from constants file" do
      hearing_location = described_class.new(facility_id: "vba_307", address: "123 Main St")

      expect(hearing_location.street_address).to eq("130 South Elmwood Ave")
    end

    it "rejects nulls and blank values" do
      hearing_location = described_class.new(facility_id: "vba_317")

      expect(hearing_location.street_address).to eq("9500 Bay Pines Blvd.")
    end
  end

  describe "vba_372" do
    it "read name, street address and ZIP code from .json constants" do
      hearing_location = described_class.new(facility_id: "vba_372", address: "123 Main St")

      expect(hearing_location.street_address).to eq("425 I Street, N.W.")
      expect(hearing_location.name).to eq("Board of Veterans' Appeals CO Office")
      expect(hearing_location.zip_code).to eq("20001")
    end
  end
end
