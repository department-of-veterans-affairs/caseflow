require "rails_helper"

describe ExternalApi::FacilitiesLocatorService, focus: true do
  context "#get_distance" do
    subject { FacilitiesLocatorService.get_nearest([0.0, 0.0], ["vha_688"]) }

    it "return list of nearest facilities" do
      expect(subject[0]).to include(:address, :lat, :long, :id, :name)
    end
  end
end
