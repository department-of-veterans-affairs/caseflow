# frozen_string_literal: true

describe PopulateEndProductSyncQueueJob, type: :job do

  let!(:veteran) { create(:veteran) }
  let!(:found_vec) { create(:vbms_ext_claim, :canceled, claimant_person_id: veteran.participant_id) }
  let!(:found_epe) { create(:end_product_establishment, :cleared, veteran_file_number: veteran.file_number, established_at: Time.zone.today, reference_id: found_vec.claim_id.to_s) }
  let!(:not_found_epe) { create(:end_product_establishment, :canceled, veteran_file_number: veteran.file_number, established_at: Time.zone.today, reference_id: found_vec.claim_id.to_s) }
  let!(:not_found_vec) { create(:vbms_ext_claim, :rdc, claimant_person_id: veteran.participant_id) }

  context "#perform" do
    it "adds the unsynced epe to the end product synce queue" do
      expect(PriorityEndProductSyncQueue.count).to eq 0
      PopulateEndProductSyncQueueJob.perform_now
      expect(PriorityEndProductSyncQueue.count).to eq 1
      expect(EndProductEstablishment.find(PriorityEndProductSyncQueue.first.end_product_establishment_id).reference_id).to eq found_vec.claim_id.to_s
      expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq found_epe.id
      expect(PriorityEndProductSyncQueue.first.status).to eq "NOT_PROCESSED"
      expect(RequestStore.store[:current_user].id).to eq(User.system_user.id)
    end

    it "doesn't add any epes if batch is empty" do
      found_epe.update!(synced_status: "CAN")
      expect(PriorityEndProductSyncQueue.count).to eq 0
      PopulateEndProductSyncQueueJob.perform_now
      expect(PriorityEndProductSyncQueue.count).to eq 0
      found_epe.update!(synced_status: "PEND")
    end

    it "doesn't add epe to queue if the epe reference_id is a lettered string (i.e. only match on matching numbers)" do
      found_epe.update!(reference_id: "wuddup yo")
      expect(PriorityEndProductSyncQueue.count).to eq 0
      PopulateEndProductSyncQueueJob.perform_now
      expect(PriorityEndProductSyncQueue.count).to eq 0
      found_epe.update!(reference_id: found_vec.claim_id.to_s)
    end

    it "will not add same epe more than once in the priorty end product sync queue table" do
      PriorityEndProductSyncQueue.create(
        end_product_establishment_id: found_epe.id
      )
      PopulateEndProductSyncQueueJob.perform_now
      expect(PriorityEndProductSyncQueue.count).to eq 1
    end

    it "will add the epe if epe synced status is nil and other conditions are met" do
      found_epe.update!(synced_status: nil)
      expect(PriorityEndProductSyncQueue.count).to eq 0
      PopulateEndProductSyncQueueJob.perform_now
      expect(PriorityEndProductSyncQueue.count).to eq 1
      found_epe.update!(synced_status: "PEND")
    end

  end

end
