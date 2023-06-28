# frozen_string_literal: true

require "./app/models/batch_processes/batch_process_priority_ep_sync.rb"

describe BatchProcessPriorityEpSync, :postgres do

  # let!(:batch) do
  #   BatchProcessPriorityEpSync.create!
  # end

  let!(:unprocessed_pepsq_record) do
    [
      PriorityEndProductSyncQueue.create!(
        end_product_establishment: create(:end_product_establishment, :out_of_sync_with_vbms)
      )
    ]
  end

  context "#find_records" do
    it "returns array with the PriorityEndProductSyncQueue record that can be batched" do
      expect(BatchProcessPriorityEpSync.find_records).to eq(unprocessed_pepsq_record)
      expect(BatchProcessPriorityEpSync.find_records.count).to eq(1)
    end

    it "returns an empty array if there are no PriorityEndProductSyncQueue records available to batch" do
      # deletes any pre-existing PEPSQ records
      PriorityEndProductSyncQueue.destroy_all
      expect(BatchProcessPriorityEpSync.find_records).to eq([])
    end
  end

  context "#create_batch!" do
    it "creates a new batch record" do
      # initial count of records on the two tables
      bppes_before_count = BatchProcessPriorityEpSync.count
      bp_before_count = BatchProcess.count

      # add another PEPSQ record to this batch
      # new_pepsq = PriorityEndProductSyncQueue.create!(
      #   end_product_establishment: create(:end_product_establishment, :out_of_sync_with_vbms))
      # new_array = unprocessed_pepsq_record.push(new_pepsq)

      # method creates a new BatchProcessPriorityEpSync object
      BatchProcessPriorityEpSync.create_batch!(unprocessed_pepsq_record)

      # expects the current number of records to be different than before
      expect(BatchProcessPriorityEpSync.count).to eq(bppes_before_count + 1)
      # expect(BatchProcess.count).to eq(bp_before_count + 1)

      # record's batch_id is not nil
      expect(BatchProcessPriorityEpSync.last.batch_id).not_to eq(nil)

      # record's batch_type matches the name of it's process type (class name)
      expect(BatchProcessPriorityEpSync.last.batch_type).to eq("BatchProcessPriorityEpSync")

      # record's state is "PRE_PROCESSING"
      expect(BatchProcessPriorityEpSync.last.state).to eq("PRE_PROCESSING")

      # record's records_attempted is equal to the number of records in the PEPSQ array
      expect(BatchProcessPriorityEpSync.last.records_attempted).to eq(unprocessed_pepsq_record.count)

      # the new BatchProcessPriorityEpSync record is returned
      # expect(BatchProcessPriorityEpSync.create_batch!(new_array)).to eq(BatchProcessPriorityEpSync.last)

      # the PEPSQ records are updated to "PRE_PROCESSING"
      # expect(BatchProcessPriorityEpSync.create_batch!(new_array)).to eq(BatchProcessPriorityEpSync.last)

      # the PEPSQ records are updated to have this batch's batch_id
      # expect(BatchProcessPriorityEpSync.create_batch!(new_array)).to eq(BatchProcessPriorityEpSync.last)
    end
  end

  # context "#process_batch!" do
  #   it "fails if the EPE doesn't have an associated VbmsExtClaim record" do
  #   end

  #   it "fails if the EPE's synced_status doesn't match the VbmsExtClaim record's level_status_code" do
  #   end

  #   it "successfully finds associated records" do
  #     batch.update!(state: "PROCESSING", started_at: Time.zone.now)

  #     pepsq = PriorityEndProductSyncQueue.create!(
  #       batch_id: batch.batch_id,
  #       status: "PRE_PROCESSING",
  #       end_product_establishment: create(
  #         :end_product_establishment,
  #         :out_of_sync_with_vbms
  #       )
  #     )

  #     expect(batch.priority_end_product_sync_queue).to be_present
  #     expect(pepsq.end_product_establishment).to be_present
  #   end

  #   it "successfully syncs the EPE" do
  #     PriorityEndProductSyncQueue.destroy_all

  #     PriorityEndProductSyncQueue.create!(
  #       batch_id: batch.batch_id,
  #       status: "PRE_PROCESSING",
  #       end_product_establishment: create(
  #         :end_product_establishment,
  #         :out_of_sync_with_vbms
  #       )
  #     )

  #     expect(PriorityEndProductSyncQueue.count).to eq(1)
  #     expect(batch.records_completed).to eq(0)
  #     expect(batch.state).to eq("PRE_PROCESSING")

  #     batch.process_batch!

  #     batch.reload

  #     expect(batch.records_completed).to eq(1)
  #     expect(batch.state).to eq("PROCESSED")
  #   end
  # end

end
