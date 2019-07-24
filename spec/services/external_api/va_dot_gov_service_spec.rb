# frozen_string_literal: true

describe ExternalApi::VADotGovService do
  before(:each) do
    stub_const("VADotGovService", Fakes::VADotGovService)
  end

  describe "#validate_address" do
    it "returns validated address" do
      result = VADotGovService.validate_address(
        address_line1: "fake address",
        address_line2: "fake address",
        address_line3: "fake address",
        city: "City",
        state: "State",
        zip_code: "Zip",
        country: "US"
      )

      expect(result[:error]).to be_nil
      expect(result[:valid_address]).to_not be_nil
    end
  end

  describe "#get_distance" do
    it "returns distance to facilities" do
      result = VADotGovService.get_distance(
        ids: %w[vha_539 vha_757 vha_539],
        lat: 0.0,
        long: 0.0
      )

      expect(result[:facilities].pluck(:facility_id)).to eq(%w[vha_539 vha_757 vha_539])
      expect(result[:error]).to be_nil
    end
  end

  describe "#get_facility_data" do
    it "returns facility data" do
      result = VADotGovService.get_facility_data(ids: %w[vha_539 vha_757 vha_539])

      expect(result[:facilities].pluck(:facility_id)).to eq(%w[vha_539 vha_757 vha_539])
      expect(result[:error]).to be_nil
    end
  end
end
