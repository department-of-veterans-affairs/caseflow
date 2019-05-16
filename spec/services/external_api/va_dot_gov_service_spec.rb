# frozen_string_literal: true

describe ExternalApi::VADotGovService do
  describe "#get_facility_data" do
    it "returns facility data" do
      results = VADotGovService.get_facility_data(ids: %w[vha_539 vha_757 vha_539])

      expect(results.pluck(:facility_id)).to eq(%w[vha_539 vha_757 vha_539])
    end
  end
end
