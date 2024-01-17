# frozen_string_literal: true

# The PriorityEndProductSyncQue is populated via the trigger that is created on creation of the vbms_ext_claim table
# The trigger is located in:
#  db/scripts/external/create_vbms_ext_claim_table.rb
#  db/scripts/
describe "vbms_ext_claim trigger to populate end_product_sync_que table", :postgres do
  context "when the trigger is added to the vbms_ext_claim table before the creation new records" do
    before(:all) do
      system("bundle exec rails r -e test db/scripts/drop_pepsq_populate_trigger_from_vbms_ext_claim.rb")
      system("bundle exec rails r -e test db/scripts/add_pepsq_populate_trigger_to_vbms_ext_claim.rb")
    end
    before do
      PriorityEndProductSyncQueue.delete_all
    end

    context "we only log inserted vbms_ext_claims" do
      let(:logged_epe1) { create(:end_product_establishment, :active, reference_id: 300_000) }
      let(:logged_ext_claim1) { create(:vbms_ext_claim, :cleared, :slc, id: 300_000) }

      it "that have a \"04%\" EP_CODE, that are cleared,
            different sync status, and are not in pepsq table" do
        logged_epe1
        logged_ext_claim1
        expect(PriorityEndProductSyncQueue.count).to eq 1
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq logged_epe1.id
      end

      let(:logged_epe2) { create(:end_product_establishment, synced_status: nil, reference_id: 300_000) }
      let(:logged_ext_claim2) { create(:vbms_ext_claim, :canceled, :hlr, id: 300_000) }

      it "that have a \"03%\" EP_CODE, that are cancelled,
            with out sync status, not in pepsq table " do
        logged_epe2
        logged_ext_claim2
        expect(PriorityEndProductSyncQueue.count).to eq 1
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq logged_epe2.id
      end

      let(:logged_epe3) { create(:end_product_establishment, synced_status: nil, reference_id: 300_000) }
      let(:logged_ext_claim3) { create(:vbms_ext_claim, :canceled, :hlr, id: 300_000, ep_code: "930") }

      it "that have a \"93%\" EP_CODE, that are cancelled,
            with out sync status, not in pepsq table " do
        logged_epe3
        logged_ext_claim3
        expect(PriorityEndProductSyncQueue.count).to eq 1
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq logged_epe3.id
      end

      let(:logged_epe4) { create(:end_product_establishment, synced_status: nil, reference_id: 300_000) }
      let(:logged_ext_claim4) { create(:vbms_ext_claim, :cleared, id: 300_000, ep_code: "680") }

      it "that have a \"68%\" EP_CODE, that are cleared,
            with out sync status, not in pepsq table " do
        logged_epe4
        logged_ext_claim4
        expect(PriorityEndProductSyncQueue.count).to eq 1
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq logged_epe4.id
      end
    end

    context "we do not log inserted (on creation) vbms_ext_claims" do
      let(:logged_epe5) { create(:end_product_establishment, synced_status: nil, reference_id: 300_000) }
      let(:logged_ext_claim5) { create(:vbms_ext_claim, :rdc, :hlr, id: 300_000) }

      it "that have a \"03%\" EP_CODE, that are rdc,
            with out sync status, not in pepsq table " do
        logged_epe5
        logged_ext_claim5
        expect(PriorityEndProductSyncQueue.count).to eq 0
      end

      let(:logged_epe6) { create(:end_product_establishment, synced_status: nil, reference_id: 300_000) }
      let(:logged_ext_claim6) { create(:vbms_ext_claim, :canceled, EP_CODE: "999", id: 300_000) }

      it "that have a wrong EP_CODE, that are canceled,
            with a nil sync status, not in pepsq table " do
        logged_epe6
        logged_ext_claim6
        expect(PriorityEndProductSyncQueue.count).to eq 0
      end

      let(:logged_epe7) { create(:end_product_establishment, synced_status: nil, reference_id: 300_000) }
      let(:logged_ext_claim7) { create(:vbms_ext_claim, :canceled, :slc, id: 300_000) }

      it "that have a wrong EP_CODE, that are canceled,
            with a nil sync status, already in the pepsq table " do
        logged_epe7
        PriorityEndProductSyncQueue.create(end_product_establishment_id: logged_epe7.id)
        logged_ext_claim7
        expect(PriorityEndProductSyncQueue.count).to eq 1
      end
    end
  end

  context "when the trigger is added and records already exist in the vbms_ext_claim table" do
    before(:all) do
      @logged_epe = create(:end_product_establishment, :active, reference_id: 300_000)
      @logged_ext_claim = create(:vbms_ext_claim, :rdc, :slc, id: 300_000)
      system("bundle exec rails r -e test db/scripts/drop_pepsq_populate_trigger_from_vbms_ext_claim.rb")
      system("bundle exec rails r -e test db/scripts/add_pepsq_populate_trigger_to_vbms_ext_claim.rb")
    end
    before do
      PriorityEndProductSyncQueue.delete_all
    end
    after(:all) do
      EndProductEstablishment.delete(@logged_epe)
      VbmsExtClaim.delete(@logged_ext_claim)
    end

    context "we only log updated vbms_ext_claims" do
      it "that have a \"04%\" EP_CODE, that are cleared,
            different sync status, and are not in pepsq table" do
        @logged_ext_claim.update(LEVEL_STATUS_CODE: "CLR")
        expect(PriorityEndProductSyncQueue.count).to eq 1
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq @logged_epe.id
      end

      it "that have a \"03%\" EP_CODE, that are cancelled,
            with out sync status, not in pepsq table " do
        @logged_epe.update(synced_status: nil)
        @logged_ext_claim.update(LEVEL_STATUS_CODE: "CAN", EP_CODE: "030")
        expect(PriorityEndProductSyncQueue.count).to eq 1
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq @logged_epe.id
      end

      it "that have a \"93%\" EP_CODE, that are cleared,
            different sync status, and are not in pepsq table" do
        @logged_ext_claim.update(LEVEL_STATUS_CODE: "CLR", EP_CODE: "930")
        expect(PriorityEndProductSyncQueue.count).to eq 1
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq @logged_epe.id
      end

      it "that have a \"68%\" EP_CODE, that are cancelled,
            with out sync status, not in pepsq table " do
        @logged_epe.update(synced_status: nil)
        @logged_ext_claim.update(LEVEL_STATUS_CODE: "CAN", EP_CODE: "680")
        expect(PriorityEndProductSyncQueue.count).to eq 1
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq @logged_epe.id
      end
    end

    context "we do not log updated vbms_ext_claims" do
      it "that have a \"03%\" EP_CODE, that are rdc,
            with out sync status, not in pepsq table " do
        @logged_ext_claim.update(LEVEL_STATUS_CODE: "RDC", EP_CODE: "030")
        expect(PriorityEndProductSyncQueue.count).to eq 0
      end

      it "that have a wrong EP_CODE, that are canceled,
            with a nil sync status, not in pepsq table " do
        @logged_epe.update(synced_status: nil)
        @logged_ext_claim.update(LEVEL_STATUS_CODE: "CAN", EP_CODE: "999")
        expect(PriorityEndProductSyncQueue.count).to eq 0
      end

      it "that have a wrong EP_CODE, that are canceled,
            with a nil sync status, already in the pepsq table " do
        PriorityEndProductSyncQueue.create(end_product_establishment_id: @logged_epe.id)
        expect(PriorityEndProductSyncQueue.count).to eq 1
      end
    end
  end

  context "when the trigger is removed from the vbms_ext_claim table" do
    before(:all) do
      system("bundle exec rails r -e test db/scripts/drop_pepsq_populate_trigger_from_vbms_ext_claim.rb")
    end
    before do
      PriorityEndProductSyncQueue.delete_all
    end
    after(:all) do
      system("bundle exec rails r -e test db/scripts/add_pepsq_populate_trigger_to_vbms_ext_claim.rb")
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
