# frozen_string_literal: true

describe Seeds::VbmsExtClaim do
  let(:seed) { Seeds::VbmsExtClaim.new }

  context "#seed!" do
    it "seeds total of 325 VBMS EXT CLAIMS, 100 High Level Review EndProduct Establishments
      100 Supplemental Claim End Product Establishments, and 125 Non Associated End Product
      Establishments" do
      seed.seed!
      expect(VbmsExtClaim.count).to eq(325)
      expect(HigherLevelReview.count).to eq(100)
      expect(SupplementalClaim.count).to eq(100)
      expect(VbmsExtClaim.where(ep_code: nil).count).to eq(125)
    end
  end

  context "#create_vbms_ext_claims_with_no_end_product_establishment" do
    it "seeds total of 125 VBMS EXT CLAIMS Not associated with an EPE" do
      seed.send(:create_vbms_ext_claims_with_no_end_product_establishment)
      expect(VbmsExtClaim.count).to eq(125)
      expect(VbmsExtClaim.where(ep_code: nil).count).to eq(125)
    end
  end

  context "#create_in_sync_epes_and_vbms_ext_claims" do
    it "seeds total of 100 VBMS EXT CLAIMS Associated with 50 High Level Review End Product
        Establishments and 50 Supplemental Claims End Product Establishments that are in sync" do
      seed.send(:create_in_sync_epes_and_vbms_ext_claims)
      expect(VbmsExtClaim.count).to eq(100)
      # need to show where VbmsExtClaim and EndProductEstablishment are in_sync
      # where Level_status_code CAN is equal to sync_status code CAN
      expect(VbmsExtClaim.where(level_status_code: "CAN").count).to eq(EndProductEstablishment
        .where(synced_status: "CAN").count)
      expect(VbmsExtClaim.where(level_status_code: "CLR").count).to eq(EndProductEstablishment
        .where(synced_status: "CLR").count)
      expect(HigherLevelReview.count).to eq(50)
      expect(SupplementalClaim.count).to eq(50)
      expect(EndProductEstablishment.count).to eq(100)
    end
  end
  context "#create_out_of_sync_epes_and_vbms_ext_claims" do
    it "seeds total of 100 VBMS EXT CLAIMS Associated with 50 High Level Review End Product
        Establishments and 50 Supplemental Claims End Product Establishments that are out
        of sync" do
      seed.send(:create_out_of_sync_epes_and_vbms_ext_claims)
      expect(VbmsExtClaim.count).to eq(100)
      # need to show where VbmsExtClaim and EndProductEstablishment are out_of_sync
      # where VbmsExtClaim.Level_status_code CAN and CLR is half of the amount of EPEs that have "PEND"
      expect(VbmsExtClaim.where(level_status_code: %w[CAN CLR]).count / 2).to eq(EndProductEstablishment
        .where(synced_status: "PEND").count)
      # where VbmsExtClaim.Level_status_code CAN and CLR is half of the amount of EPEs that have "CAN" or "CLR"
      expect(VbmsExtClaim.where(level_status_code: %w[CAN CLR]).count / 2).to eq(EndProductEstablishment
        .where(synced_status: %w[CAN CLR]).count)
      expect(HigherLevelReview.count).to eq(50)
      expect(SupplementalClaim.count).to eq(50)
      expect(EndProductEstablishment.count).to eq(100)
    end
  end
end
