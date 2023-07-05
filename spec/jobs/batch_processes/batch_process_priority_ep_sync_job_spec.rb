# frozen_string_literal: true

require "./app/jobs/batch_processes/batch_process_priority_ep_sync_job.rb"

describe BatchProcessPriorityEpSyncJob, type: :job do
  # creates 110 PEPSQ records
  before(:each) do
    110.times do
      PriorityEndProductSyncQueue.create!(end_product_establishment: create(:end_product_establishment, :active_hlr))
    end
  end

  context "#perform" do
    it "batch object is successfully created " do
      # the number of PEPSQ table records matches the amount of records in :pepsq_records
      expect(PriorityEndProductSyncQueue.count).to eq(110)
      expect(BatchProcessPriorityEpSync.count).to eq(0)

      # perform the sync
      BatchProcessPriorityEpSyncJob.perform_now

      # check that a new batch object was created
      expect(BatchProcessPriorityEpSync.count).to eq(1)
    end
  end

  it "raises an error if there are no PEPSQ records to batch" do
    # destroy all PEPSQ records
    PriorityEndProductSyncQueue.destroy_all
    expect(PriorityEndProductSyncQueue.count).to eq 0

    # perform the sync
    BatchProcessPriorityEpSyncJob.perform_now

    # custom error message sent to rails logger
    expect(Rails.logger.info == "No Records Available to Batch.  Time: #{Time.zone.now}")

    # raises a StandardError
    expect { BatchProcessPriorityEpSyncJob.perform }.to raise_error(StandardError)
  end
end
