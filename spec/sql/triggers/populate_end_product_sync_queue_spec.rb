# frozen_string_literal: true

describe "vbms_ext_claim trigger to populate end_product_sync_que table", :postgres do
  context "when the trigger is added to the vbms_ext_claim table before the creation new records" do
    before(:all) do
      system("make add-populate-pepsq-trigger")
    end
    before do
      PriorityEndProductSyncQueue.delete_all
    end
    after(:all) do
      system("remove add-populate-pepsq-trigger")
    end

    context "we only log inserted vbms_ext_claims" do
      let(:logged_epe1) { create(:end_product_establishment, :active, reference_id: 300_000) }
      let(:logged_ext_claim1) { create(:vbms_ext_claim, :cleared, :slc, id: 300_000) }

      it "that are cleared, have a \"04%\" EP_CODE,
            different sync status, and are not in pepsq table" do
        logged_epe1
        logged_ext_claim1
        expect(PriorityEndProductSyncQueue.count).to eq 1
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq logged_epe1.id
      end

      let(:logged_epe2) { create(:end_product_establishment, synced_status: nil, reference_id: 300_000) }
      let(:logged_ext_claim2) { create(:vbms_ext_claim, :canceled, :hlr, id: 300_000) }

      it "that are cancelled, have a \"03%\" EP_CODE,
            with out sync status, not in pepsq table " do
        logged_epe2
        logged_ext_claim2
        expect(PriorityEndProductSyncQueue.count).to eq 1
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq logged_epe2.id
      end
    end

    context "we do not log inserted (on creation) vbms_ext_claims" do
      let(:logged_epe3) { create(:end_product_establishment, synced_status: nil, reference_id: 300_000) }
      let(:logged_ext_claim3) { create(:vbms_ext_claim, :rdc, :hlr, id: 300_000) }

      it "that are rdc, have a \"03%\" EP_CODE,
            with out sync status, not in pepsq table " do
        logged_epe3
        logged_ext_claim3
        expect(PriorityEndProductSyncQueue.count).to eq 0
      end

      let(:logged_epe4) { create(:end_product_establishment, synced_status: nil, reference_id: 300_000) }
      let(:logged_ext_claim4) { create(:vbms_ext_claim, :canceled, EP_CODE: "999", id: 300_000) }

      it "that are canceled, have a wrong EP_CODE,
            with a nil sync status, not in pepsq table " do
        logged_epe4
        logged_ext_claim4
        expect(PriorityEndProductSyncQueue.count).to eq 0
      end

      let(:logged_epe5) { create(:end_product_establishment, synced_status: nil, reference_id: 300_000) }
      let(:logged_ext_claim5) { create(:vbms_ext_claim, :canceled, :slc, id: 300_000) }

      it "that are canceled, have a wrong EP_CODE,
            with a nil sync status, already in the pepsq table " do
        logged_epe5
        PriorityEndProductSyncQueue.create(end_product_establishment_id: logged_epe5.id)
        logged_ext_claim5
        expect(PriorityEndProductSyncQueue.count).to eq 1
      end
    end
  end

  context "when the trigger is added and records already exist in the vbms_ext_claim table" do
    before(:all) do
      @logged_epe = create(:end_product_establishment, :active, reference_id: 300_000)
      @logged_ext_claim = create(:vbms_ext_claim, :rdc, :slc, id: 300_000)
      system("make add-populate-pepsq-trigger")
    end
    before do
      PriorityEndProductSyncQueue.delete_all
    end
    after(:all) do
      EndProductEstablishment.delete(@logged_epe)
      VbmsExtClaim.delete(@logged_ext_claim)
      system("remove add-populate-pepsq-trigger")
    end

    context "we only log updated vbms_ext_claims" do
      it "that are cleared, have a \"04%\" EP_CODE,
            different sync status, and are not in pepsq table" do
        @logged_ext_claim.update(LEVEL_STATUS_CODE: "CLR")
        expect(PriorityEndProductSyncQueue.count).to eq 1
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq @logged_epe.id
      end

      it "that are cancelled, have a \"03%\" EP_CODE,
            with out sync status, not in pepsq table " do
        @logged_epe.update(synced_status: nil)
        @logged_ext_claim.update(LEVEL_STATUS_CODE: "CAN", EP_CODE: "030")
        expect(PriorityEndProductSyncQueue.count).to eq 1
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq @logged_epe.id
      end
    end

    context "we do not log updated vbms_ext_claims" do
      it "that are rdc, have a \"03%\" EP_CODE,
            with out sync status, not in pepsq table " do
        @logged_ext_claim.update(LEVEL_STATUS_CODE: "RDC", EP_CODE: "030")
        expect(PriorityEndProductSyncQueue.count).to eq 0
      end

      it "that are canceled, have a wrong EP_CODE,
            with a nil sync status, not in pepsq table " do
        @logged_epe.update(synced_status: nil)
        @logged_ext_claim.update(LEVEL_STATUS_CODE: "CAN", EP_CODE: "999")
        expect(PriorityEndProductSyncQueue.count).to eq 0
      end

      it "that are canceled, have a wrong EP_CODE,
            with a nil sync status, already in the pepsq table " do
        PriorityEndProductSyncQueue.create(end_product_establishment_id: @logged_epe.id)
        expect(PriorityEndProductSyncQueue.count).to eq 1
      end
    end
  end

  context "when the trigger is removed from the vbms_ext_claim table" do
    before(:all) do
      system("make remove-populate-pepsq-trigger")
    end

    let(:logged_epe) { create(:end_product_establishment, :active, reference_id: 300_000) }
    let(:logged_ext_claim) { create(:vbms_ext_claim, :cleared, :slc, id: 300_000) }

    it "no records should be inserted into pepsq on creation of new vbms_ext_claim records" do
      logged_epe
      logged_ext_claim
      expect(PriorityEndProductSyncQueue.count).to eq 0
    end

    it "no records should be inserted into pepsq on update of existing vbms_ext_claim records" do
      logged_epe
      logged_ext_claim
      logged_epe.update(synced_status: nil)
      logged_ext_claim.update(LEVEL_STATUS_CODE: "CAN", EP_CODE: "030")
      expect(PriorityEndProductSyncQueue.count).to eq 0
    end
  end
end
