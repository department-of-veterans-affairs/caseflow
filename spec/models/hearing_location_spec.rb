# frozen_string_literal: true

describe HearingLocation do
  describe ".street_address" do
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

  describe ".full_address" do
    it "rejects nulls and blank values" do
      hearing_location = described_class.new(facility_id: "vba_317", city: "St. Petersburg", state: "")

      expect(hearing_location.full_address).to eq("9500 Bay Pines Blvd., St. Petersburg")
    end

    it "formats correctly" do
      hearing_location = described_class.new(
        facility_id: "vba_318", city: "Winston-Salem", state: "NC", zip_code: "27155"
      )

      expect(hearing_location.full_address).to eq("251 N. Main Street Federal Building, Winston-Salem NC 27155")
    end
  end
end
