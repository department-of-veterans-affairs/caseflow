# frozen_string_literal: true

require "rails_helper"

describe HearingLocation do
  describe "#street_address" do
    it "pulls from constants file" do
      hearing_location = described_class.new(facility_id: "vba_307", address: "123 Main St")

      expect(hearing_location.street_address).to eq("130 South Elmwood Ave, Suite 601")
    end
  end
end
