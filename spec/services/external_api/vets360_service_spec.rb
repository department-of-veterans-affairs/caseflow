require "rails_helper"

describe ExternalApi::Vets360Service, focus: true do
  context "#geocode" do
    subject { Vets360Service.geocode("425 Eye St. NW, Washington, DC") }

    it "returns latitude and longitude" do
      expect(subject).to eq [0.0, 0.0]
    end
  end
end
