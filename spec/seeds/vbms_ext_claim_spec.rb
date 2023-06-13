# frozen_string_literal: true

describe Seeds::VbmsExtClaim do
  let(:seed) { Seeds::VbmsExtClaim.new }

  context "#seed!" do
    it "seeds total of 325 VBMS EXT CLAIMS with 100 High Level Review and
        100 Supplmental Claims Associated and 200 Associated with EndProduct" do
      seed.seed!
      expect(VbmsExtClaim.count).to eq(325)
      expect(HigherLevelReview.count).to eq(100)
      expect(SupplementalClaim.count).to eq(100)
      expect(EndProductEstablishment.count).to eq(200)
    end
  end
end
