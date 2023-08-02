# frozen_string_literal: true

describe CaseflowStuckRecord, :postgres do
  before do
    # Force the jobs to only run long enough to iterate through the loop once each.
    # This overrides the default job duration which is supposed to continue
    # iterating through the job for an hour.
    #
    # Changing the sleep duration to 0 prevents latency.
    stub_const("PopulateEndProductSyncQueueJob::JOB_DURATION", 0.0001.seconds)
    stub_const("PopulateEndProductSyncQueueJob::SLEEP_DURATION", 0.seconds)
    stub_const("PriorityEpSyncBatchProcessJob::JOB_DURATION", 0.001.seconds)
    stub_const("PriorityEpSyncBatchProcessJob::SLEEP_DURATION", 0.seconds)
  end

  describe "#end_product_establishment" do
    let!(:end_product_establishment) do
      create(:end_product_establishment, :canceled_hlr_with_cleared_vbms_ext_claim)
    end

    let!(:caseflow_stuck_record) do
      PopulateEndProductSyncQueueJob.perform_now
      3.times do
        PriorityEndProductSyncQueue.first.update!(last_batched_at: nil)
        PriorityEpSyncBatchProcessJob.perform_now
      end
      CaseflowStuckRecord.first
    end

    it "will return the end_product_establishment when the stuck record is from the Priority End Product Sync Queue" do
      expect(caseflow_stuck_record.end_product_establishment).to eq(end_product_establishment)
    end
  end
end
