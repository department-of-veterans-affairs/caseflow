# frozen_string_literal: true

require "./app/models/batch_processes/batch_process_priority_ep_sync.rb"

describe BatchProcessPriorityEpSync, :postgres do

  # array of 100 PEPSQ records
  let!(:pepsq_records) { create_list(:priority_end_product_sync_queue, 100) }

  context "#find_records" do
    it "returns array with the PriorityEndProductSyncQueue record that can be batched" do
      # create one additional PEPSQ record to test that no more
      # than 100 records are associated with the batch
      PriorityEndProductSyncQueue.create!(end_product_establishment: create(:end_product_establishment, :active_hlr))

      expect(PriorityEndProductSyncQueue.count).to eq(101)

      # method should return array of the batch's PEPSQ records
      expect(BatchProcessPriorityEpSync.find_records).to eq(pepsq_records)

      expect(BatchProcessPriorityEpSync.find_records.count).to eq(100)
    end

    it "returns an empty array if there are no PriorityEndProductSyncQueue records available to batch" do
      # deletes any pre-existing PEPSQ records
      PriorityEndProductSyncQueue.destroy_all

      # if there aren't any PEPSQ records, an empty array is returned
      expect(BatchProcessPriorityEpSync.find_records).to eq([])
    end
  end

  context "#create_batch!" do
    it "creates a new batch record" do
      # initial count of records on the two tables
      bppes_before_count = BatchProcessPriorityEpSync.count
      bp_before_count = BatchProcess.count

      # method creates a new BatchProcessPriorityEpSync object
      BatchProcessPriorityEpSync.create_batch!(pepsq_records)

      # the current number of records includes the new record
      expect(BatchProcessPriorityEpSync.count).to eq(bppes_before_count + 1)
      expect(BatchProcess.count).to eq(bp_before_count + 1)

      # record's batch_id is not nil
      expect(BatchProcessPriorityEpSync.last.batch_id).not_to eq(nil)

      # record's batch_type matches the name of it's process type (class name)
      expect(BatchProcessPriorityEpSync.last.batch_type).to eq("BatchProcessPriorityEpSync")

      # record's state is "PRE_PROCESSING"
      expect(BatchProcessPriorityEpSync.last.state).to eq("PRE_PROCESSING")

      # record's records_attempted is equal to the number of records in the PEPSQ array
      expect(BatchProcessPriorityEpSync.last.records_attempted).to eq(pepsq_records.count)
    end
  end

  context "#process_batch!" do
    # create a batch containing 100 PEPSQ records
    let!(:batch) {
      BatchProcess.create!(
        state: "PRE_PROCESSING",
        batch_type: "BatchProcessPriorityEpSync",
        started_at: Time.zone.now,
        batch_id: SecureRandom.uuid,
        records_attempted: 100,
        priority_end_product_sync_queue: create_list(:priority_end_product_sync_queue, 100)
      )
    }

    # update PEPSQ records to belong to this batch
    PriorityEndProductSyncQueue.all.each do |pepsq_rec|
      pepsq_rec.update!(batch_id: batch.batch_id)
    end

    it "calls the method on the correct batch and finds its associated PEPSQ records" do
      # batch should have 100 pepsq records
      expect(batch.priority_end_product_sync_queue.count).to eq(100)
    end

    it "successfully syncs the EPE" do
      # create vbms_ext_claim association objects for each EPE
      batch.priority_end_product_sync_queue.all.each do |pepsq_rec|
        VbmsExtClaim.create!(
          claim_id: pepsq_rec.end_product_establishment.reference_id,
          level_status_code: "CLR",
          claim_date: Time.zone.now - 1.day,
          sync_id: 1,
          createddt: Time.zone.now - 1.day,
          establishment_date: Time.zone.now - 1.day,
          lastupdatedt: Time.zone.now,
          expirationdt: Time.zone.now + 5.days,
          version: 22,
          prevent_audit_trig: 2
        )
      end

      # all EPE's should have an associated VbmsExtClaim object
      batch.priority_end_product_sync_queue do |pepsq|
        expect(pepsq.end_product_establishment.vbms_ext_claim).not_to eq(nil)
      end

      # batch pre-processing state
      expect(batch.records_attempted).to eq(100)
      expect(batch.records_completed).to eq(0)
      expect(batch.state).to eq("PRE_PROCESSING")

      # run the method
      batch.process_batch!

      # batch record is updated to completed state with no failed records
      expect(batch.records_failed).to eq(0)
      expect(batch.records_completed).to eq(100)
      expect(batch.state).to eq("COMPLETED")
    end

    # STILL NEEDS WORKED (error not being raised)
    it "raises error if the EPE doesn't have an associated VbmsExtClaim record" do
      # EPE's should have no associated VbmsExtClaim
      batch.priority_end_product_sync_queue.all.each do |pepsq|
        expect(pepsq.end_product_establishment.vbms_ext_claim).to eq(nil)
      end

      batch.process_batch!

      expect(Rails.logger.error == "Claim Not In VBMS_EXT_CLAIM.")

      # raises a StandardError
      expect { batch.process_batch! }.to raise_error(Caseflow::Error::PriorityEndProductSyncError)
    end

    # STILL NEEDS WORKED
    it "fails if the EPE's synced_status doesn't match the VbmsExtClaim record's level_status_code" do

    end
  end

end
