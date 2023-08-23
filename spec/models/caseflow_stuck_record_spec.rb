# frozen_string_literal: true

describe CaseflowStuckRecord, :pr_28544, :postgres do
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
